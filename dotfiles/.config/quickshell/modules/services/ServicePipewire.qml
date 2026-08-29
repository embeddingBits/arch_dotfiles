pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import Quickshell.Services.Pipewire

Singleton{
    id: root   

    readonly property var nodes: Pipewire.nodes.values.reduce((acc, node) => {
        if(!node.isStream){
            if(node.isSink)
            acc.sinks.push(node);
            else if(node.audio)
            acc.sources.push(node);
        }else{
            acc.playbacks.push(node)
        }
        return acc;
    },{
        sources: [],
        sinks: [],
        playbacks: []
    })

    readonly property list<PwNode> sinks: nodes.sinks
    readonly property list<PwNode> sources: nodes.sources
    readonly property list<PwNode> playbacks: nodes.playbacks

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    
    readonly property bool muted:    !!sink?.audio?.muted
    readonly property bool micMuted: !!source?.audio?.muted
    readonly property real volume:    sink?.audio?.volume ?? 0
    readonly property real micVolume: source?.audio?.volume ?? 0

    function toggleMute(): void {
        if (sink?.audio) sink.audio.muted = !sink.audio.muted
    }

    function toggleMicMute(): void {
        if (source?.audio) source.audio.muted = !source.audio.muted
    }

    function setVolume(newVolume: real): void{
        if(sink?.ready && sink?.audio){
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, newVolume))
        }
    }

    function setMicVolume(newVolume: real): void{
        if(source?.ready && source?.audio){
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(1, newVolume))
        }
    }

    function setSinkVolume(node: PwNode, newVolume: real){
        if(node?.ready && node?.audio){
            node.audio.muted = false;
            node.audio.volume = Math.max(0, Math.min(1, newVolume));
        }
    }

    function getName(value: PwAudioChannel): string{
        return PwAudioChannel.toString(value)
    }

    function incrementVolume(amount: real): void{
        setVolume(volume + (amount))
    }

    function decrementVolume(amount: real): void{
        setVolume(volume - (amount))
    }

    function setAudioSink(newSink: PwNode): void{
        Pipewire.preferredDefaultAudioSink = newSink;
    }

    function setAudioSource(newSource: PwNode): void{
        Pipewire.preferredDefaultAudioSource = newSource
    }

    PwObjectTracker{
        objects: [...root.sinks, ...root.sources, ...root.playbacks]
    }

}

