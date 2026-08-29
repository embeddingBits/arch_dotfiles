pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // ─── Storage ───────────────────────────────────────────────────────────────
    readonly property string _storePath: Quickshell.env("HOME") + "/.local/share/quickshell/todos.json"

    // ─── Raw data ──────────────────────────────────────────────────────────────
    property var todos: []

    // ─── Filter / search state ─────────────────────────────────────────────────
    property string searchText: ""
    property string filterTag: ""       // "" = all tags
    property int filterPriority: -1     // -1 = all, 0=none 1=low 2=medium 3=high
    property string filterStatus: "all" // "all" | "active" | "completed"

    // ─── Sort state ────────────────────────────────────────────────────────────
    property string sortBy: "createdAt" // "createdAt" | "dueDate" | "priority" | "title"
    property bool sortAsc: true

    // ─── Derived: filtered + sorted view ──────────────────────────────────────
    readonly property var filteredTodos: {
        let result = [...root.todos]

        if (root.filterStatus === "active")
            result = result.filter(t => !t.completed)
        else if (root.filterStatus === "completed")
            result = result.filter(t => t.completed)

        if (root.filterTag !== "")
            result = result.filter(t => t.tags && t.tags.includes(root.filterTag))

        if (root.filterPriority !== -1)
            result = result.filter(t => t.priority === root.filterPriority)

        if (root.searchText.trim() !== "") {
            const q = root.searchText.toLowerCase()
            result = result.filter(t =>
                t.title.toLowerCase().includes(q) ||
                (t.description && t.description.toLowerCase().includes(q)) ||
                (t.tags && t.tags.some(tag => tag.toLowerCase().includes(q)))
            )
        }

        result.sort((a, b) => {
            let va, vb
            switch (root.sortBy) {
                case "title":    va = a.title.toLowerCase(); vb = b.title.toLowerCase(); break
                case "priority": va = a.priority;            vb = b.priority;            break
                case "dueDate":  va = a.dueDate || "9999-12-31"; vb = b.dueDate || "9999-12-31"; break
                default:         va = a.createdAt;           vb = b.createdAt
            }
            if (va < vb) return root.sortAsc ? -1 : 1
            if (va > vb) return root.sortAsc ?  1 : -1
            return 0
        })

        return result
    }

    // ─── Stats ─────────────────────────────────────────────────────────────────
    readonly property var stats: ({
        total:       root.todos.length,
        active:      root.todos.filter(t => !t.completed).length,
        completed:   root.todos.filter(t =>  t.completed).length,
        overdue:     root.todos.filter(t => !t.completed && t.dueDate && t.dueDate < _today()).length,
        dueToday:    root.todos.filter(t => !t.completed && t.dueDate === _today()).length,
        highPriority: root.todos.filter(t => !t.completed && t.priority === 3).length
    })

    // ─── All unique tags in use ────────────────────────────────────────────────
    readonly property var allTags: {
        const set = new Set()
        root.todos.forEach(t => { if (t.tags) t.tags.forEach(tag => set.add(tag)) })
        return Array.from(set).sort()
    }

    // ─── Signals ───────────────────────────────────────────────────────────────
    signal todoAdded(var todo)
    signal todoRemoved(string id)
    signal todoUpdated(var todo)
    signal listChanged()

    // ─── File I/O ──────────────────────────────────────────────────────────────
    FileView {
        id: todoFile
        path: root._storePath

        onLoaded: {
            try {
                const data = JSON.parse(todoFile.text())
                root.todos = Array.isArray(data) ? data : []
            } catch (e) {
                console.error("ServiceTodo: failed to parse todos.json:", e)
                root.todos = []
            }
        }

        onLoadFailed: { root.todos = [] }
    }

    Process {
        id: saveProcess
        command: ["bash", "-c", ""]
        running: false
    }

    Process {
        id: mkdirProcess
        command: ["bash", "-c", "mkdir -p " + Quickshell.env("HOME") + "/.local/share/quickshell"]
        running: true
    }

    // ─── Private helpers ───────────────────────────────────────────────────────
    function _today(): string { return new Date().toISOString().slice(0, 10) }
    function _now(): string   { return new Date().toISOString() }
    function _uuid(): string  { return Date.now().toString(36) + Math.random().toString(36).slice(2, 7) }

    function _saveTodos(): void {
        const json = JSON.stringify(root.todos, null, 2)
        const escaped = json.replace(/'/g, "'\\''")
        saveProcess.command = ["bash", "-c", "printf '%s' '" + escaped + "' > " + root._storePath]
        saveProcess.running = true
        root.listChanged()
    }

    function _findIndex(id: string): int {
        for (let i = 0; i < root.todos.length; i++) {
            if (root.todos[i].id === id) return i
        }
        return -1
    }

    // ─── Date formatting ───────────────────────────────────────────────────────

    // Human-friendly date: "Today", "Yesterday", "Mon, Mar 9", "Mar 9"
    function formatDate(isoString: string): string {
        if (!isoString) return ""
        const d = new Date(isoString)
        const now = new Date()
        const todayStr = now.toDateString()
        const yest = new Date(now); yest.setDate(now.getDate() - 1)
        if (d.toDateString() === todayStr)      return "Today"
        if (d.toDateString() === yest.toDateString()) return "Yesterday"
        const diffDays = Math.floor((now - d) / 86400000)
        if (diffDays < 7) return Qt.formatDate(d, "ddd, MMM d")
        return Qt.formatDate(d, "MMM d")
    }

    // Due date chip label: "Overdue", "Due today", "Due tomorrow", "Due Mar 15"
    function dueDateLabel(dueDate: string): string {
        if (!dueDate) return ""
        const today = _today()
        const tomorrow = (() => { const d = new Date(); d.setDate(d.getDate() + 1); return d.toISOString().slice(0, 10) })()
        if (dueDate < today)     return "Overdue"
        if (dueDate === today)   return "Due today"
        if (dueDate === tomorrow) return "Tomorrow"
        return "Due " + Qt.formatDate(new Date(dueDate), "MMM d")
    }

    // Priority display helpers
    function priorityLabel(priority: int): string {
        switch (priority) {
            case 1: return "Low"
            case 2: return "Medium"
            case 3: return "High"
            default: return "None"
        }
    }

    function priorityIcon(priority: int): string {
        switch (priority) {
            case 1: return "arrow_downward"
            case 2: return "arrow_upward"
            case 3: return "priority_high"
            default: return "flag"
        }
    }

    // ─── Per-todo state helpers ────────────────────────────────────────────────
    function isOverdue(todo: var): bool {
        return !todo.completed && !!todo.dueDate && todo.dueDate < _today()
    }

    function isDueToday(todo: var): bool {
        return !todo.completed && todo.dueDate === _today()
    }

    // ─── CRUD ──────────────────────────────────────────────────────────────────
    function addTodo(title: string, description: string, priority: int, tags: var, dueDate: string): var {
        const todo = {
            id:          _uuid(),
            title:       title.trim(),
            description: description || "",
            completed:   false,
            completedAt: "",
            priority:    priority || 0,
            tags:        tags || [],
            dueDate:     dueDate || "",
            createdAt:   _now(),
            updatedAt:   _now()
        }
        root.todos = [...root.todos, todo]
        _saveTodos()
        root.todoAdded(todo)
        return todo
    }

    function removeTodo(id: string): void {
        const idx = _findIndex(id)
        if (idx === -1) return
        const copy = [...root.todos]
        copy.splice(idx, 1)
        root.todos = copy
        _saveTodos()
        root.todoRemoved(id)
    }

    function updateTodo(id: string, changes: var): var {
        const idx = _findIndex(id)
        if (idx === -1) return null
        const copy = [...root.todos]
        copy[idx] = Object.assign({}, copy[idx], changes, { updatedAt: _now() })
        root.todos = copy
        _saveTodos()
        root.todoUpdated(copy[idx])
        return copy[idx]
    }

    function toggleComplete(id: string): void {
        const idx = _findIndex(id)
        if (idx === -1) return
        const completing = !root.todos[idx].completed
        updateTodo(id, { completed: completing, completedAt: completing ? _now() : "" })
    }

    function markComplete(id: string): void   { updateTodo(id, { completed: true,  completedAt: _now() }) }
    function markIncomplete(id: string): void  { updateTodo(id, { completed: false, completedAt: "" }) }
    function setTitle(id: string, title: string): void { updateTodo(id, { title: title.trim() }) }
    function setDescription(id: string, desc: string): void { updateTodo(id, { description: desc }) }
    function setPriority(id: string, priority: int): void   { updateTodo(id, { priority: priority }) }
    function setDueDate(id: string, dueDate: string): void  { updateTodo(id, { dueDate: dueDate }) }

    function addTag(id: string, tag: string): void {
        const idx = _findIndex(id)
        if (idx === -1) return
        const t = root.todos[idx]
        if (t.tags && t.tags.includes(tag)) return
        updateTodo(id, { tags: [...(t.tags || []), tag] })
    }

    function removeTag(id: string, tag: string): void {
        const idx = _findIndex(id)
        if (idx === -1) return
        updateTodo(id, { tags: (root.todos[idx].tags || []).filter(tg => tg !== tag) })
    }

    function clearCompleted(): void {
        root.todos = root.todos.filter(t => !t.completed)
        _saveTodos()
    }

    function clearAll(): void {
        root.todos = []
        _saveTodos()
    }

    function reorder(fromIndex: int, toIndex: int): void {
        if (fromIndex === toIndex) return
        const copy = [...root.todos]
        const [item] = copy.splice(fromIndex, 1)
        copy.splice(toIndex, 0, item)
        root.todos = copy
        _saveTodos()
    }

    // ─── Filter / sort ─────────────────────────────────────────────────────────
    function search(text: string): void          { root.searchText = text }
    function setFilterTag(tag: string): void     { root.filterTag = tag }
    function setFilterPriority(p: int): void     { root.filterPriority = p }
    function setFilterStatus(s: string): void    { root.filterStatus = s }
    function setSortBy(field: string, asc: bool): void { root.sortBy = field; root.sortAsc = asc }

    function resetFilters(): void {
        root.searchText     = ""
        root.filterTag      = ""
        root.filterPriority = -1
        root.filterStatus   = "all"
        root.sortBy         = "createdAt"
        root.sortAsc        = true
    }

    // ─── Queries ───────────────────────────────────────────────────────────────
    function getTodoById(id: string): var  { return root.todos.find(t => t.id === id) ?? null }
    function getOverdue(): var             { return root.todos.filter(t => isOverdue(t)) }
    function getDueToday(): var            { return root.todos.filter(t => isDueToday(t)) }
    function getByTag(tag: string): var    { return root.todos.filter(t => t.tags && t.tags.includes(tag)) }
    function getByPriority(p: int): var    { return root.todos.filter(t => t.priority === p) }
}
