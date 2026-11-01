class_name CarPhysics
extends RefCounted
## Route geometry + a small driver model. Port of src/world/carPhysics.js
##
## The JS functions marked 'worklet' ran on the UI thread; here they are plain static functions.
## Not ported (they were unused in the JS app): `lightState` and the `reaction` setting.
##
## A built route is a Dictionary:
##   { L, N, ds, X, Y, D, FR, zones }   (+ "lights" and "drive" are added by CarDriver)
##   L = route length (tiles), N = number of samples, ds = L / N,
##   X / Y = grid position per sample, D = sprite direction (0 sw, 1 se, 2 ne, 3 nw) per sample,
##   FR = heading frame (0..TURN_FRAMES-1) per sample, zones = [[start, length], ...] of the corners.

const DIRS: Array[String] = ["sw", "se", "ne", "nw"]
const TURN_FRAMES := 20
const BEZIER_STEPS := 20


## Sprite direction for a grid movement (dx, dy): 0 = sw, 1 = se, 2 = ne, 3 = nw.
static func move_dir(dx: float, dy: float) -> int:
	var sx := dx - dy
	var sy := dx + dy
	if sy >= 0.0:
		return 0 if sx < 0.0 else 1
	return 2 if sx > 0.0 else 3


## Closed route with rounded corners, resampled every `step` tiles. Returns {} when it has < 3 points.
static func build_path(points: Array, radius: float = 1.3, step: float = 0.05, zone_pad: float = 0.4) -> Dictionary:
	var n := points.size()
	if n < 3:
		return {}

	var raw: Array[Vector2] = []
	var arcs: Array = []  # [first raw index, last raw index, radius]
	for i in n:
		var p0: Vector2 = points[(i + n - 1) % n]
		var p1: Vector2 = points[i]
		var p2: Vector2 = points[(i + 1) % n]
		var l01 := p0.distance_to(p1)
		var l12 := p2.distance_to(p1)
		var r := minf(radius, minf(l01 / 2.0, l12 / 2.0))
		var a := p1 + (p0 - p1) * (r / l01)
		var b := p1 + (p2 - p1) * (r / l12)
		var first := raw.size()
		for k in range(BEZIER_STEPS + 1):
			var t := float(k) / float(BEZIER_STEPS)
			var u := 1.0 - t
			raw.append(a * (u * u) + p1 * (2.0 * u * t) + b * (t * t))
		arcs.append([first, raw.size() - 1, r])

	var m := raw.size()
	var cum := PackedFloat64Array()
	cum.append(0.0)
	for i in range(1, m):
		cum.append(cum[i - 1] + raw[i].distance_to(raw[i - 1]))
	var total: float = cum[m - 1] + raw[0].distance_to(raw[m - 1])
	cum.append(total)

	# s = 0 is the end of the first corner (middle of a straight)
	var s_off: float = cum[int(arcs[0][1])]
	var count := maxi(8, int(round(total / step)))
	var ds := total / float(count)
	var xs := PackedFloat64Array()
	var ys := PackedFloat64Array()
	var seg := 0
	for i in count:
		var s := fposmod(s_off + float(i) * ds, total)
		if i == 0 or s < cum[seg]:
			seg = 0
		while seg < m - 1 and cum[seg + 1] <= s:
			seg += 1
		var pa := raw[seg]
		var pb := raw[(seg + 1) % m]
		var seg_len: float = cum[seg + 1] - cum[seg]
		if seg_len == 0.0:
			seg_len = 1.0
		var f := (s - cum[seg]) / seg_len
		xs.append(pa.x + (pb.x - pa.x) * f)
		ys.append(pa.y + (pb.y - pa.y) * f)

	var dirs := PackedInt32Array()
	var frames := PackedInt32Array()
	for i in count:
		var j := (i + 1) % count
		var dx := xs[j] - xs[i]
		var dy := ys[j] - ys[i]
		dirs.append(move_dir(dx, dy))
		# heading frame (0..TURN_FRAMES-1) per sample, for the turn spritesheet
		frames.append(posmod(int(round(atan2(dy, dx) / TAU * float(TURN_FRAMES))), TURN_FRAMES))

	# corner zones: [start, length]
	var zones: Array = []
	for arc in arcs:
		var arc_r: float = arc[2]
		if arc_r <= 0.01:
			continue
		var arc_len: float = cum[int(arc[1])] - cum[int(arc[0])]
		zones.append([fposmod(cum[int(arc[0])] - s_off - zone_pad, total), arc_len + zone_pad * 2.0])

	return {"L": total, "N": count, "ds": ds, "X": xs, "Y": ys, "D": dirs, "FR": frames, "zones": zones}


## Light rows: [sStop, stopFor]. `lights` = [{"at": Vector2, "stop_for": seconds}, ...]
static func build_lights(lights: Array, path: Dictionary, half_length: float = 0.85) -> Array:
	var out: Array = []
	var count: int = path["N"]
	var xs: PackedFloat64Array = path["X"]
	var ys: PackedFloat64Array = path["Y"]
	for l in lights:
		var at: Vector2 = l["at"]
		var best := 0
		var best_d := INF
		for i in count:
			var d := Vector2(xs[i], ys[i]).distance_to(at)
			if d < best_d:
				best_d = d
				best = i
		out.append([fposmod(float(best) * float(path["ds"]) - half_length, float(path["L"])), float(l.get("stop_for", 5.0))])
	return out


## Position on the route at distance `s`. Returns [gx, gy, dir, frame].
static func path_at(R: Dictionary, s: float) -> Array:
	var L: float = R["L"]
	var ds: float = R["ds"]
	var count: int = R["N"]
	var xs: PackedFloat64Array = R["X"]
	var ys: PackedFloat64Array = R["Y"]
	var dirs: PackedInt32Array = R["D"]
	var frames: PackedInt32Array = R["FR"]
	var f := fposmod(s, L) / ds
	var fl := int(floor(f))
	var i := fl % count
	var j := (i + 1) % count
	var k := f - float(fl)
	return [xs[i] + (xs[j] - xs[i]) * k, ys[i] + (ys[j] - ys[i]) * k, dirs[i], frames[i]]


## One physics step. Returns [s, v, a, waited, releasedLight]
##   s = distance along the route, v = speed, a = acceleration, t = clock (s), dt = step (s),
##   w = seconds waited at the current light, k = light we were released from (-1 = none)
static func step_car(s: float, v: float, a: float, t: float, dt: float, R: Dictionary, w: float, k: int) -> Array:
	var c: Dictionary = R["drive"]
	var L: float = R["L"]
	var p := fposmod(s, L)
	var plan := float(c["brake"])
	var corner_speed := float(c["corner_speed"])
	var v_limit := float(c["cruise"])
	var hold := false
	var nw := w
	var nk := k
	var arrived := false

	# slow down for corners
	for z in R["zones"]:
		var rel := fposmod(p - float(z[0]), L)
		if rel <= float(z[1]):
			v_limit = minf(v_limit, corner_speed)
		else:
			var dist := L - rel
			v_limit = minf(v_limit, sqrt(corner_speed * corner_speed + 2.0 * plan * dist))

	# (virtual) red lights
	var lights: Array = R["lights"]
	for i in lights.size():
		var l: Array = lights[i]
		var d := fposmod(float(l[0]) - p, L)
		if d > L - 0.4:
			if nk == i:
				nk = -1  # passed the line
			continue
		if nk == i:
			continue  # already released from this light
		var d_eff := d - float(c["margin"])
		if d_eff < 0.45 and v < 0.08:
			arrived = true
			nw += dt
			if nw >= float(l[1]):
				nk = i
				nw = 0.0
				arrived = false
				continue  # waiting time is over, go
			hold = true
		elif d_eff <= 0.01:
			hold = true
		v_limit = minf(v_limit, sqrt(2.0 * plan * maxf(d_eff, 0.0)))
	if not arrived:
		nw = 0.0

	var v_target := v_limit
	if hold or t < float(c["start_delay"]):
		v_target = 0.0

	var gain := float(c.get("gain", 4.0))
	var a_des := clampf(gain * (v_target - v), -float(c["brake_max"]), float(c["accel"]))

	var dj := float(c["jerk"]) * dt
	var na := a + clampf(a_des - a, -dj, dj)
	var nv := v + na * dt
	if nv < 0.0:
		nv = 0.0
		na = 0.0
	if hold and nv < 0.05:
		nv = 0.0
		na = 0.0
	return [s + (v + nv) / 2.0 * dt, nv, na, nw, nk]
