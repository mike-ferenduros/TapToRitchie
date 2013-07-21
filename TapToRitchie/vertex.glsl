attribute vec2 xy;
attribute vec2 st;

varying vec2 frag_st;

void main()
{
	frag_st = st;

	gl_Position = vec4(xy,0.0,1.0);
}
