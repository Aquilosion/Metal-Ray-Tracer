//
//  RayTrace.metal
//  Ray Tracer
//
//  Created by Robert Pugh on 2023-04-02.
//

#include <metal_stdlib>
using namespace metal;

struct Projection {
	float2   size;
	float4x4 inverseProjection;
	float    defocusStrength;
};

struct Material {
	float3 diffuse;
	float3 emission;
	float3 metalness;
	float3 opacity;
};

struct Sphere {
	float3   position;
	float    radius;
	Material material;
};

struct Scene {
	const device Sphere* spheres;
	uint                 sphereCount;
};

struct Ray {
	float3 origin;
	float3 direction;
};

struct HitInfo {
	float    distance;
	float3   position;
	float3   normal;
	Material material;
	uint     index;
};

float random(thread uint &seed) {
	seed = seed * 747796405 + 2891336453;
	uint result = ((seed >> ((seed >> 28) + 4)) ^ seed) * 277803737;
	result = (result >> 22) ^ result;
	return result / 4294967295.0;
}

float normalDistributionRandom(thread uint &seed) {
	float theta = 2 * M_PI_F * random(seed);
	float rho = sqrt(-2 * log(random(seed)));
	return rho * cos(theta);
}

float3 randomDirection(thread uint &seed) {
	return normalize(
		float3(
			normalDistributionRandom(seed),
			normalDistributionRandom(seed),
			normalDistributionRandom(seed)
		)
	 );
}

float2 randomPointInCircle(thread uint &seed) {
	float angle = random(seed) * 2 * M_PI_F;
	float2 pointOnCircle = float2(cos(angle), sin(angle));
	return pointOnCircle * sqrt(random(seed));
}

HitInfo raySphereIntersection(Ray ray, Sphere sphere, bool insideSphere) {
	float3 offsetRayOrigin = ray.origin - sphere.position;
	
	float a = dot(ray.direction, ray.direction);
	float b = 2 * dot(offsetRayOrigin, ray.direction);
	float c = dot(offsetRayOrigin, offsetRayOrigin) - sphere.radius * sphere.radius;
	
	float discriminant = b * b - 4 * a * c;
	
	HitInfo hitInfo;
	hitInfo.distance = INFINITY;
	
	if (discriminant > 0) {
		float distance = (-b + mix(-1.0, 1.0, insideSphere) * sqrt(discriminant)) / (2 * a);
		
		if (distance >= 0) {
			hitInfo.distance = distance;
			hitInfo.position = ray.origin + ray.direction * distance;
			hitInfo.normal = normalize(hitInfo.position - sphere.position);
			hitInfo.material = sphere.material;
		}
	}
	
	return hitInfo;
}

HitInfo hitTest(Ray ray, Scene scene, thread bool *insideSphere) {
	HitInfo closest;
	closest.distance = INFINITY;
	
	for (uint i = 0; i < scene.sphereCount; ++i) {
		HitInfo hitInfo = raySphereIntersection(ray, scene.spheres[i], insideSphere[i]);
		
		if (hitInfo.distance < closest.distance) {
			hitInfo.index = i;
			closest = hitInfo;
		}
	}
	
	return closest;
}

float3 environmentColor(float3 direction) {
	float3 skyColorHorizon = float3(0.8, 0.9, 1.0);
	float3 skyColorZenith = float3(0.2, 0.4, 0.8);
	
	float3 groundColor = float3(0.3, 0.4, 0.4);
	
	float3 sunLightDirection = normalize(float3(0, -1, 1));
	float sunFocus = 500;
	float sunIntensity = 100;
	
	float skyGradientT = pow(smoothstep(0, 0.4, direction.y), 0.35);
	float3 skyGradient = mix(skyColorHorizon, skyColorZenith, skyGradientT);
	float sun = pow(max(0.0, dot(direction, -sunLightDirection)), sunFocus) * sunIntensity;
	
	float groundToSkyT = smoothstep(-0.1, 0, direction.y);
	float sunMask = groundToSkyT >= 1;
	return mix(groundColor, skyGradient, groundToSkyT) + sun * sunMask;
}

float3 traceRay(Ray ray, Scene scene, thread uint &seed) {
	float3 incomingColor = 0;
	float3 rayColor = 1;
	float currentRefractiveIndex = 1;
	
	const float materialRefractiveIndex = 1.6;
	
	bool insideSphere[128] = { false };
	
	for (uint i = 0; i < 8; ++i) {
		HitInfo hit = hitTest(ray, scene, insideSphere);
		
		if (hit.distance == INFINITY) {
			incomingColor += environmentColor(ray.direction) * rayColor;
			break;
		}
		
		bool isExteriorHit = !insideSphere[hit.index];
		
		if (!isExteriorHit) {
			hit.normal = -hit.normal;
		}
		
		ray.origin = hit.position;
		
		float3 diffuseDirection = normalize(hit.normal + randomDirection(seed));
		float3 specularDirection = reflect(ray.direction, hit.normal);
		
		float refractionChange = mix(materialRefractiveIndex / currentRefractiveIndex, currentRefractiveIndex / materialRefractiveIndex, isExteriorHit);
		float3 transparencyDirection = refract(ray.direction, hit.normal, refractionChange);
		
		bool isSpecularBounce = random(seed) < 0.2 && isExteriorHit;
		bool isTransparentBounce = (!isSpecularBounce && random(seed) > (dot(hit.material.opacity, 1.0) / 3.0)) || !isExteriorHit;
		
		ray.direction = mix(
			mix(
				diffuseDirection, specularDirection, hit.material.metalness * isSpecularBounce
			),
			transparencyDirection,
			isTransparentBounce
		);
		
		incomingColor += hit.material.emission * rayColor;
		rayColor *= mix(mix(hit.material.diffuse, 1, isSpecularBounce), 1.0 - hit.material.opacity, isTransparentBounce);
		
		if (isTransparentBounce) {
			currentRefractiveIndex /= refractionChange;
			insideSphere[hit.index] = !insideSphere[hit.index];
		}
		
		float sigma = 1 / 512;
		
		if (rayColor.x <= sigma && rayColor.y <= sigma && rayColor.z <= sigma) {
			break;
		}
	}
	
	return incomingColor;
}

Ray projectedRay(uint2 index, Projection projection, thread uint &seed) {
	float2 jitter = float2(
		(random(seed) - 0.5),
		(random(seed) - 0.5)
	);
	
	float2 position = (
		(float2(index) + jitter) / projection.size - 0.5
	) * float2(2, -2);
	
	float2 jitteredPosition = position + randomPointInCircle(seed) * projection.defocusStrength;
	
	float4 transformedOrigin = projection.inverseProjection * float4(jitteredPosition, -1, 1);
	float3 origin = transformedOrigin.xyz / transformedOrigin.w;
	
	float4 transformedDestination = projection.inverseProjection * float4(position, 1, 1);
	float3 destination = transformedDestination.xyz / transformedDestination.w;
	
	Ray ray;
	ray.origin = origin;
	ray.direction = normalize(destination - origin);
	
	return ray;
}

kernel void generateTexture(
	texture2d<float, access::read_write> outputTexture [[texture(0)]],
	uint2                                index         [[thread_position_in_grid]],
	constant uint&                       frameIndex    [[buffer(0)]],
	constant Projection&                 projection    [[buffer(1)]],
	constant uint&                       sphereCount   [[buffer(2)]],
	const device Sphere*                 spheres       [[buffer(3)]]
) {
	uint seed = index.x + index.y * uint(projection.size.x) + frameIndex * uint(projection.size.x * projection.size.y);
	
	Scene scene;
	scene.spheres = spheres;
	scene.sphereCount = sphereCount;
	
	int sampleCount = 16;
	
	float3 color = 0;
	
	for (int i = 0; i < sampleCount; ++i) {
		Ray ray = projectedRay(index, projection, seed);
		
		color += traceRay(ray, scene, seed);
	}
	
	color /= sampleCount;
	
	float3 outColor;
	if (frameIndex == 0) {
		outColor = color;
	} else {
		float3 inColor = outputTexture.read(index).xyz;
		outColor = (inColor * frameIndex + color) / (float(frameIndex) + 1);
	}
	
	outputTexture.write(float4(outColor, 1), index);
}
