extern float fov;
extern float angle;
extern float rx;
extern float ry;
extern float cz;
extern vec4 selCol;
extern float width;
extern float height;
extern float shader;
extern float positionFlag;

//love_ScreenSize.x

#ifdef VERTEX
vec4 position(mat4 mvp_matrix, vec4 vertex){
	vec4 v = mvp_matrix * vertex;
	if(shader==0){ //hand
		v.y *= -1.0;
		float dy = v.y;
		if(v.y>=0){
			v.y = 1.0;
		}else{
			v.y = -1.0;
		}
		dy -= v.y;
		v.y += 1;
		float z = v.y*sin(angle) - cz*cos(angle);
		v.y = v.y*cos(angle) + cz*sin(angle) + dy;
		v.w = 1.0 + z/fov;
		v.y -= 1;
		v.y += 0.5;
		v.y *= -1.0;
	}else if(shader==2){
		//no shader
	}else{ //everywhere else
		v.y *= -1.0;
		v.y += 1;
		float z = v.y*sin(angle) - cz*cos(angle);
		v.y = v.y*cos(angle) + cz*sin(angle);
		v.w = 1.0 + z/fov;
		v.y -= 1;
		v.y += 0.5;
		v.y *= -1.0;
	}
	return v;
}
#endif
 
#ifdef PIXEL
void effects(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
	vec4 pixel = Texel(texture, texture_coords);
	love_Canvases[0] = pixel * color;
	
	if(positionFlag==1.0){
		love_Canvases[1] = vec4(0.0, 0.0, 0.0, 0.0);
	}else{
		love_Canvases[1] = selCol;
	}
	
	if(positionFlag==1.0 && pixel.r==1.0 && pixel.g==1.0 && pixel.b==1.0){
		float x = texture_coords.x*width - width/2.0 + rx;
		float y = texture_coords.y*height - height/2.0 + ry;
		float b = mod(x,256);
		float r = mod(y,256);
		float g = floor(x/256+8) + floor(y/256+8)*16;
		love_Canvases[2] = vec4(r/255.0, g/255.0, b/255.0, 1.0);
	}else{
		love_Canvases[2] = vec4(0.0, 0.0, 0.0, 0.0);
	}
}
#endif


















