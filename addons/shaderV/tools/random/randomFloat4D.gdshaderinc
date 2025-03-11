highp float _randFloat4D(vec4 input) {
	float f = dot(fract(input) + fract(input * 2.32184321231),vec4(129.898,782.33,944.32214932,122.2834234542));
	return fract(sin(f) * 437588.5453);
}
