precision mediump float;

uniform sampler2D tex;
uniform sampler2D dottex;

varying vec2 frag_st;
varying vec2 dots_st;

uniform vec3 col1;
uniform vec3 col2;

void main()
{
	vec3 col = texture2D( tex, frag_st ).rgb;
	float i = (col.r+col.g+col.b) * (1.0/3.0);

	float dotval = texture2D( dottex, dots_st ).r;

	i = ((i-dotval)*10.0)+0.5;

	gl_FragColor = vec4(
		mix( col1, col2, clamp(i,0.0,1.0) ),
		1.0
	);
}
