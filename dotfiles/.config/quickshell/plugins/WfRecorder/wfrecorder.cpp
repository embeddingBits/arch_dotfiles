#include "wfrecorder.h"

#include <QDebug>
#include <QPointer>
#include <csignal>
#include <unistd.h>
#include <sys/types.h>

WfRecorder::WfRecorder(QObject *parent) : QObject(parent)
{
    m_process = new QProcess(this);
    m_process->setProgram("sh");
    m_process->setProcessChannelMode(QProcess::ForwardedChannels);

    // Put the child shell in its own process group so we can send signals
    // to the whole group (sh + wf-recorder child) with a single kill().
    m_process->setChildProcessModifier([]() {
        ::setpgid(0, 0);
    });

    connect(m_process, &QProcess::started,
            this,      &WfRecorder::onStarted);

    connect(m_process,
            QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &WfRecorder::onFinished);

    connect(m_process, &QProcess::errorOccurred,
            this,      &WfRecorder::onError);

    m_timer = new QTimer(this);
    m_timer->setInterval(1000);
    m_timer->setSingleShot(false);
    connect(m_timer, &QTimer::timeout, this, &WfRecorder::onTick);
}

void WfRecorder::start(const QString &shellCmd,
                       const QString &mode,
                       const QString &filename)
{
    if (m_recording) return;

    m_mode      = mode;
    m_filename  = filename;
    m_elapsed   = 0;
    m_stopping  = false;

    emit modeChanged();
    emit filenameChanged();
    emit elapsedChanged();

    m_process->setArguments({"-c", shellCmd});
    m_process->start();
}

void WfRecorder::stop()
{
    if (!m_recording) return;

    m_stopping = true;

    // Send SIGINT to the entire process group — reaches wf-recorder
    // even though our direct child is the sh wrapper.
    if (m_process->state() != QProcess::NotRunning) {
        ::kill(-(pid_t)m_process->processId(), SIGINT);

        // Hard fallback: if still running after 5 s, force-kill.
        // QPointer guards against use-after-free if the engine reloads.
        QPointer<WfRecorder> guard(this);
        QTimer::singleShot(5000, this, [guard]() {
            if (!guard) return;
            if (guard->m_process->state() != QProcess::NotRunning) {
                qWarning() << "[WfRecorder] force-killing after timeout";
                guard->m_process->kill();
            }
        });
    }
}

QString WfRecorder::formattedTime() const
{
    return QString("%1:%2")
        .arg(m_elapsed / 60, 2, 10, QChar('0'))
        .arg(m_elapsed % 60, 2, 10, QChar('0'));
}

// ── slots ──────────────────────────────────────────────────────────────────

void WfRecorder::onStarted()
{
    m_recording = true;
    m_timer->start();
    emit recordingChanged();
    qDebug() << "[WfRecorder] started, PID" << m_process->processId();
}

void WfRecorder::onFinished(int exitCode, QProcess::ExitStatus status)
{
    m_timer->stop();
    const int duration = m_elapsed;
    m_elapsed   = 0;
    m_recording = false;
    m_stopping  = false;

    emit elapsedChanged();
    emit recordingChanged();
    emit recordingStopped(duration);

    qDebug() << "[WfRecorder] finished —"
             << "exit" << exitCode
             << "| status" << (status == QProcess::CrashExit ? "signal/crash" : "normal")
             << "| duration" << duration << "s";
}

void WfRecorder::onError(QProcess::ProcessError error)
{
    // QProcess reports Crashed whenever the process exits via a signal.
    // If we sent SIGINT intentionally, this is expected — onFinished will
    // do the real cleanup, so we just swallow the error here.
    if (error == QProcess::Crashed && m_stopping)
        return;

    m_timer->stop();
    m_recording = false;
    m_stopping  = false;
    emit recordingChanged();

    QString msg;
    switch (error) {
        case QProcess::FailedToStart:
            msg = "Failed to start — is wf-recorder installed?"; break;
        case QProcess::Crashed:
            msg = "wf-recorder crashed unexpectedly";            break;
        default:
            msg = "Process error " + QString::number(error);     break;
    }

    qWarning() << "[WfRecorder] error:" << msg;
    emit recordingError(msg);
}

void WfRecorder::onTick()
{
    ++m_elapsed;
    emit elapsedChanged();
}
