precision mediump float;

uniform sampler2D tex;

varying vec2 frag_st;

void main()
{
	gl_FragColor = texture2D( tex, frag_st );
}
