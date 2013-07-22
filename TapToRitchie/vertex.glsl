attribute vec2 xy;
attribute vec2 st;
uniform vec2 screensize;

varying vec2 frag_st;
varying vec2 dots_st;

void main()
{
	frag_st = st;

	gl_Position = vec4(xy,0.0,1.0);
	dots_st = (xy+vec2(1.0,1.0)) * 0.5 * screensize / 80.0;
}
