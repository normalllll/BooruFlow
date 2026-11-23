"""Shares the iOS audio session between players: counts its users and
deactivates it only when the last one closes."""
import sys

path = sys.argv[1]
src = open(path).read()
if 'audiounit_session_use_count' in src:
    sys.exit(0)

def sub(old, new):
    global src
    if src.count(old) != 1:
        sys.exit(f'patch_audiounit: expected one match for:\n{old}')
    src = src.replace(old, new)

sub('''struct priv {
    AudioUnit audio_unit;
    double device_latency;
};
''', '''#include <pthread.h>

struct priv {
    AudioUnit audio_unit;
    double device_latency;
    bool session_acquired;
};

static pthread_mutex_t audiounit_session_lock = PTHREAD_MUTEX_INITIALIZER;
static int audiounit_session_use_count;

static void acquire_audio_session(struct ao *ao, AVAudioSessionCategoryOptions options,
                                  NSInteger pref_channels)
{
    struct priv *p = ao->priv;
    AVAudioSession *instance = AVAudioSession.sharedInstance;

    pthread_mutex_lock(&audiounit_session_lock);
    if (audiounit_session_use_count == 0) {
        [instance setCategory:AVAudioSessionCategoryPlayback withOptions:options error:nil];
        [instance setMode:AVAudioSessionModeMoviePlayback error:nil];
        [instance setActive:YES error:nil];
        [instance setPreferredOutputNumberOfChannels:pref_channels error:nil];
    }
    audiounit_session_use_count++;
    p->session_acquired = true;
    pthread_mutex_unlock(&audiounit_session_lock);
}

static void release_audio_session(struct ao *ao)
{
    struct priv *p = ao->priv;

    if (!p->session_acquired)
        return;
    pthread_mutex_lock(&audiounit_session_lock);
    if (audiounit_session_use_count > 0)
        audiounit_session_use_count--;
    p->session_acquired = false;
    if (audiounit_session_use_count == 0) {
        [AVAudioSession.sharedInstance
            setActive:NO
            withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
            error:nil];
    }
    pthread_mutex_unlock(&audiounit_session_lock);
}
''')

sub('''    [instance setCategory:AVAudioSessionCategoryPlayback withOptions:options error:nil];
    [instance setMode:AVAudioSessionModeMoviePlayback error:nil];
    [instance setActive:YES error:nil];
    [instance setPreferredOutputNumberOfChannels:prefChannels error:nil];
''', '''    acquire_audio_session(ao, options, prefChannels);
''')

sub('''coreaudio_error:
    talloc_free(layout);
    return false;''', '''coreaudio_error:
    release_audio_session(ao);
    talloc_free(layout);
    return false;''')

sub('''    AudioComponentInstanceDispose(p->audio_unit);

    [AVAudioSession.sharedInstance
        setActive:NO
        withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
        error:nil];
}''', '''    AudioComponentInstanceDispose(p->audio_unit);
    release_audio_session(ao);
}''')

open(path, 'w').write(src)
