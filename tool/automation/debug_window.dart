// Debug assertions and the same isolated file-RPC/window capture workflow.
import 'release_video.dart' show runOwnedAutomation;

Future<void> main() => runOwnedAutomation(release: false);
