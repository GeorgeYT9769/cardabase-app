#!/usr/bin/env bash
# Runs the integration tests.
#
#   ./tool/run_integration_tests.sh                 # headless, no device needed
#   ./tool/run_integration_tests.sh -d f6720309     # on a device or emulator
#
# With a device the whole directory goes through one `flutter test`. Without
# one the tests run on the headless tester, which hosts a single app at a time:
# pointing `flutter test` at the directory would only ever run the first file
# ("Unable to start the app on the device" for the rest), so every file is run
# in its own invocation there.
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ $# -gt 0 ]]; then
  exec flutter test integration_test "$@"
fi

status=0
while IFS= read -r -d '' test_file; do
  echo "==> $test_file"
  if ! flutter test "$test_file" -d flutter-tester; then
    status=1
  fi
done < <(find integration_test -name '*_test.dart' -print0 | sort -z)

exit $status
