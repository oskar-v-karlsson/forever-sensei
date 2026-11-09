PYTHON ?= python3

.PHONY: check reports reports-dry zip clean

# Offline checks: loads the addon in Lua 5.1 with a fake client, text rules, layout, talents, data vs client dump.
check:
	$(PYTHON) tools/check.py

# Translation reports copied from the game (clipboard, pbpaste): apply suggestions, log the rest, bump, zip.
reports:
	$(PYTHON) tools/reports.py

# Same, from the clipboard, but only show what would happen.
reports-dry:
	$(PYTHON) tools/reports.py --dry-run

# dist/ForeverSensei-v<version>.zip (unzip into the AddOns folder).
zip: check
	$(PYTHON) -c "import sys; sys.path.insert(0, 'tools'); import reports; print('built', reports.build_zip())"

clean:
	rm -rf dist tools/__pycache__
