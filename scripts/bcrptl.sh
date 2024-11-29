#!/usr/bin/env nu

def main [...json] {
	let type = try { $env.type } catch { |e| $e.msg; return 0 }
	if $type == "hash" {
		let pswd = try { $json | get 0 | from json | get password } catch { |e| $e.msg; return 0 }
		/usr/local/bin/bcrypt-tool hash $"($pswd)" cost 15 | complete | rename hash | to json -r
	} else {
		let pswd = try { $json | get 0 | from json | get password } catch { |e| $e.msg; return 0 }
		let hash = try { $json | get 0 | from json | get hash } catch { |e| $e.msg; return 0 }
		/usr/local/bin/bcrypt-tool match $"($pswd)" $"($hash)" | complete | rename match | to json -r
	}
}
