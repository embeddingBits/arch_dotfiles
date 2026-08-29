#pragma once

#include <QObject>
#include <QProcess>
#include <QTimer>
#include <QtQml/qqml.h>
#include <QQmlEngine>
#include <QJSEngine>

class WfRecorder : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool    recording READ isRecording NOTIFY recordingChanged)
    Q_PROPERTY(int     elapsed   READ elapsed     NOTIFY elapsedChanged)
    Q_PROPERTY(QString mode      READ mode        NOTIFY modeChanged)
    Q_PROPERTY(QString filename  READ filename    NOTIFY filenameChanged)

public:
    explicit WfRecorder(QObject *parent = nullptr);

    static WfRecorder *create(QQmlEngine *, QJSEngine *) {
        // Single C++-owned instance — survives engine reloads without double-free.
        static WfRecorder *instance = nullptr;
        if (!instance) {
            instance = new WfRecorder();
            QJSEngine::setObjectOwnership(instance, QJSEngine::CppOwnership);
        }
        return instance;
    }

    bool    isRecording() const { return m_recording; }
    int     elapsed()     const { return m_elapsed; }
    QString mode()        const { return m_mode; }
    QString filename()    const { return m_filename; }

    Q_INVOKABLE void start(const QString &shellCmd,
                           const QString &mode,
                           const QString &filename);
    Q_INVOKABLE void stop();
    Q_INVOKABLE QString formattedTime() const;

signals:
    void recordingChanged();
    void elapsedChanged();
    void modeChanged();
    void filenameChanged();
    void recordingStopped(int duration);
    void recordingError(const QString &message);

private slots:
    void onStarted();
    void onFinished(int exitCode, QProcess::ExitStatus status);
    void onError(QProcess::ProcessError error);
    void onTick();

private:
    QProcess *m_process  = nullptr;
    QTimer   *m_timer    = nullptr;
    int       m_elapsed  = 0;
    QString   m_mode;
    QString   m_filename;
    bool      m_recording = false;
    bool      m_stopping  = false;   // true when we sent SIGINT intentionally
};
