"""Run after `flutter create --platforms=windows .` to brand the app. Idempotent."""
import re
from pathlib import Path

NAME = 'NOTORYX Connect'

main = Path('windows/runner/main.cpp')
text, count = re.subn(r'window\.Create\(L"[^"]*"', f'window.Create(L"{NAME}"', main.read_text())
if count != 1:
    raise SystemExit('Could not set the window title')
main.write_text(text)

resource = Path('windows/runner/Runner.rc')
text = resource.read_text()
for field in ('FileDescription', 'ProductName'):
    text, count = re.subn(rf'(VALUE "{field}", )"[^"]*"', rf'\1"{NAME}"', text)
    if count != 1:
        raise SystemExit(f'Could not set {field}')
resource.write_text(text)

# local_auth_windows and geolocator_windows build with the old /await
# coroutines, which Visual Studio 2026 rejects unless this is defined. Remove
# once those plugins move to C++20 coroutines.
cmake = Path('windows/CMakeLists.txt')
text = cmake.read_text()
flag = 'add_compile_definitions(_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS)'
if flag not in text:
    text, count = re.subn(r'^(project\([^)]*\)\n)', lambda m: m.group(1) + flag + '\n', text, count=1, flags=re.M)
    if count != 1:
        raise SystemExit('Could not add the coroutine flag to windows/CMakeLists.txt')
    cmake.write_text(text)
print('Prepared Windows branding')
