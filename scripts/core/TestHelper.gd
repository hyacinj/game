extends Node

var passed: int = 0
var failed: int = 0

func check(condition: bool, msg: String) -> void:
	if condition:
		passed += 1
		print("[TEST]  PASS: ", msg)
	else:
		failed += 1
		print("[TEST] *FAIL: ", msg)

func assert_eq(actual, expected, msg: String) -> void:
	check(actual == expected, "%s (got=%s, want=%s)" % [msg, str(actual), str(expected)])

func assert_gt(actual, minimum, msg: String) -> void:
	check(actual > minimum, "%s (got=%s, need >%s)" % [msg, str(actual), str(minimum)])

func assert_lt(actual, maximum, msg: String) -> void:
	check(actual < maximum, "%s (got=%s, need <%s)" % [msg, str(actual), str(maximum)])

func assert_range(actual, lo, hi, msg: String) -> void:
	check(actual >= lo and actual <= hi, "%s (got=%s, range=[%s,%s])" % [msg, str(actual), str(lo), str(hi)])

func summary() -> void:
	print("[TEST] ======== SUMMARY: %d passed, %d failed ========" % [passed, failed])
