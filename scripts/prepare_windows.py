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
print('Prepared Windows branding')
