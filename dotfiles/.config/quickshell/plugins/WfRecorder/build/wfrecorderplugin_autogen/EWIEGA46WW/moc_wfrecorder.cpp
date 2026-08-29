/****************************************************************************
** Meta object code from reading C++ file 'wfrecorder.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.11.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../wfrecorder.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'wfrecorder.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.11.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {
struct qt_meta_tag_ZN10WfRecorderE_t {};
} // unnamed namespace

template <> constexpr inline auto WfRecorder::qt_create_metaobjectdata<qt_meta_tag_ZN10WfRecorderE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "WfRecorder",
        "QML.Element",
        "auto",
        "QML.Singleton",
        "true",
        "recordingChanged",
        "",
        "elapsedChanged",
        "modeChanged",
        "filenameChanged",
        "recordingStopped",
        "duration",
        "recordingError",
        "message",
        "onStarted",
        "onFinished",
        "exitCode",
        "QProcess::ExitStatus",
        "status",
        "onError",
        "QProcess::ProcessError",
        "error",
        "onTick",
        "start",
        "shellCmd",
        "mode",
        "filename",
        "stop",
        "formattedTime",
        "recording",
        "elapsed"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'recordingChanged'
        QtMocHelpers::SignalData<void()>(5, 6, QMC::AccessPublic, QMetaType::Void),
        // Signal 'elapsedChanged'
        QtMocHelpers::SignalData<void()>(7, 6, QMC::AccessPublic, QMetaType::Void),
        // Signal 'modeChanged'
        QtMocHelpers::SignalData<void()>(8, 6, QMC::AccessPublic, QMetaType::Void),
        // Signal 'filenameChanged'
        QtMocHelpers::SignalData<void()>(9, 6, QMC::AccessPublic, QMetaType::Void),
        // Signal 'recordingStopped'
        QtMocHelpers::SignalData<void(int)>(10, 6, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 11 },
        }}),
        // Signal 'recordingError'
        QtMocHelpers::SignalData<void(const QString &)>(12, 6, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 13 },
        }}),
        // Slot 'onStarted'
        QtMocHelpers::SlotData<void()>(14, 6, QMC::AccessPrivate, QMetaType::Void),
        // Slot 'onFinished'
        QtMocHelpers::SlotData<void(int, QProcess::ExitStatus)>(15, 6, QMC::AccessPrivate, QMetaType::Void, {{
            { QMetaType::Int, 16 }, { 0x80000000 | 17, 18 },
        }}),
        // Slot 'onError'
        QtMocHelpers::SlotData<void(QProcess::ProcessError)>(19, 6, QMC::AccessPrivate, QMetaType::Void, {{
            { 0x80000000 | 20, 21 },
        }}),
        // Slot 'onTick'
        QtMocHelpers::SlotData<void()>(22, 6, QMC::AccessPrivate, QMetaType::Void),
        // Method 'start'
        QtMocHelpers::MethodData<void(const QString &, const QString &, const QString &)>(23, 6, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 24 }, { QMetaType::QString, 25 }, { QMetaType::QString, 26 },
        }}),
        // Method 'stop'
        QtMocHelpers::MethodData<void()>(27, 6, QMC::AccessPublic, QMetaType::Void),
        // Method 'formattedTime'
        QtMocHelpers::MethodData<QString() const>(28, 6, QMC::AccessPublic, QMetaType::QString),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'recording'
        QtMocHelpers::PropertyData<bool>(29, QMetaType::Bool, QMC::DefaultPropertyFlags, 0),
        // property 'elapsed'
        QtMocHelpers::PropertyData<int>(30, QMetaType::Int, QMC::DefaultPropertyFlags, 1),
        // property 'mode'
        QtMocHelpers::PropertyData<QString>(25, QMetaType::QString, QMC::DefaultPropertyFlags, 2),
        // property 'filename'
        QtMocHelpers::PropertyData<QString>(26, QMetaType::QString, QMC::DefaultPropertyFlags, 3),
    };
    QtMocHelpers::UintData qt_enums {
    };
    QtMocHelpers::UintData qt_constructors {};
    QtMocHelpers::ClassInfos qt_classinfo({
            {    1,    2 },
            {    3,    4 },
    });
    return QtMocHelpers::metaObjectData<WfRecorder, void>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums, qt_constructors, qt_classinfo);
}
Q_CONSTINIT const QMetaObject WfRecorder::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN10WfRecorderE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN10WfRecorderE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN10WfRecorderE_t>.metaTypes,
    nullptr
} };

void WfRecorder::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<WfRecorder *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->recordingChanged(); break;
        case 1: _t->elapsedChanged(); break;
        case 2: _t->modeChanged(); break;
        case 3: _t->filenameChanged(); break;
        case 4: _t->recordingStopped((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 5: _t->recordingError((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 6: _t->onStarted(); break;
        case 7: _t->onFinished((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QProcess::ExitStatus>>(_a[2]))); break;
        case 8: _t->onError((*reinterpret_cast<std::add_pointer_t<QProcess::ProcessError>>(_a[1]))); break;
        case 9: _t->onTick(); break;
        case 10: _t->start((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[3]))); break;
        case 11: _t->stop(); break;
        case 12: { QString _r = _t->formattedTime();
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (WfRecorder::*)()>(_a, &WfRecorder::recordingChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (WfRecorder::*)()>(_a, &WfRecorder::elapsedChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (WfRecorder::*)()>(_a, &WfRecorder::modeChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (WfRecorder::*)()>(_a, &WfRecorder::filenameChanged, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (WfRecorder::*)(int )>(_a, &WfRecorder::recordingStopped, 4))
            return;
        if (QtMocHelpers::indexOfMethod<void (WfRecorder::*)(const QString & )>(_a, &WfRecorder::recordingError, 5))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<bool*>(_v) = _t->isRecording(); break;
        case 1: *reinterpret_cast<int*>(_v) = _t->elapsed(); break;
        case 2: *reinterpret_cast<QString*>(_v) = _t->mode(); break;
        case 3: *reinterpret_cast<QString*>(_v) = _t->filename(); break;
        default: break;
        }
    }
}

const QMetaObject *WfRecorder::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *WfRecorder::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN10WfRecorderE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int WfRecorder::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 13)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 13;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 13)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 13;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 4;
    }
    return _id;
}

// SIGNAL 0
void WfRecorder::recordingChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void WfRecorder::elapsedChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void WfRecorder::modeChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void WfRecorder::filenameChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}

// SIGNAL 4
void WfRecorder::recordingStopped(int _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 4, nullptr, _t1);
}

// SIGNAL 5
void WfRecorder::recordingError(const QString & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 5, nullptr, _t1);
}
QT_WARNING_POP
