#version 450 core
layout(local_size_x = 16, local_size_y = 16) in;
layout(binding = 0, rgba32f) uniform image2D imgPathTrace;
#include common/uniforms.glsl
#include common/globals.glsl
#include common/intersection.glsl
#include common/sampling.glsl
#include common/envmap.glsl
#include common/anyhit.glsl
#include common/closest_hit.glsl
#include common/disney.glsl
#include common/lambert.glsl
#include common/pathtrace.glsl

void main(void)
{
    ivec2 localCoord = ivec2(gl_GlobalInvocationID.xy);
    if (localCoord.x >= tileResolution.x || localCoord.y >= tileResolution.y) return;
    ivec2 globalCoord=localCoord+ivec2(tileStartPos);
    vec2 coordsTile =vec2(globalCoord) / resolution; //mix(tileOffset, tileOffset + invNumTiles, texcoords);

    InitRNG(vec2(globalCoord).xy, frameNum);

    float r1 = 2.0 * rand();
    float r2 = 2.0 * rand();

    vec2 jitter;
    jitter.x = r1 < 1.0 ? sqrt(r1) - 1.0 : 1.0 - sqrt(2.0 - r1);
    jitter.y = r2 < 1.0 ? sqrt(r2) - 1.0 : 1.0 - sqrt(2.0 - r2);

    jitter /= (resolution * 0.5);
    vec2 d = (coordsTile * 2.0 - 1.0) + jitter;

    float scale = tan(camera.fov * 0.5);
    d.y *= resolution.y / resolution.x * scale;
    d.x *= scale;
    vec3 rayDir = normalize(d.x * camera.right + d.y * camera.up + camera.forward);

    vec3 focalPoint = camera.focalDist * rayDir;
    float cam_r1 = rand() * TWO_PI;
    float cam_r2 = rand() * camera.aperture;
    vec3 randomAperturePos = (cos(cam_r1) * camera.right + sin(cam_r1) * camera.up) * sqrt(cam_r2);
    vec3 finalRayDir = normalize(focalPoint - randomAperturePos);

    Ray ray = Ray(camera.position + randomAperturePos, finalRayDir);

    vec4 accumColor =imageLoad(imgPathTrace, globalCoord);
    
    if(false){
        vec4 pixelColor = PathTrace(ray);
        vec4 result = pixelColor + accumColor;
        //vec4 result=vec4(1,0,0,1);
        imageStore(imgPathTrace, globalCoord, result);
    }
    else{
        int depth=RayDepth(ray, INF);

        vec4 pixelColor = vec4(vec3(float(depth)/bvhDepth),1.0);
        vec4 result=pixelColor + accumColor;
        //vec4 result=vec4(1,0,0,1);
        imageStore(imgPathTrace, globalCoord, result);
    }
    

    
}