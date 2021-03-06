
__kernel void pl_project_lambert_azimuthal_equal_area_s(
    __global float16 *xy_in,
    __global float16 *xy_out,
    const unsigned int count,

    float scale,
    float x0,
    float y0,

    float phi0,
    float lambda0,

    float sinPhi0,
    float cosPhi0
) {
    int i = get_global_id(0);

    float8 lambda = radians(xy_in[i].even) - lambda0;
    float8 phi    = radians(xy_in[i].odd);

    float8 x, y;
    float8 b, sinLambda, cosLambda, sinPhi, cosPhi;

    sinLambda = sincos(lambda, &cosLambda);
    sinPhi = sincos(phi, &cosPhi);

    b = sqrt(2.f / (1.f + sinPhi0 * sinPhi + cosPhi0 * cosPhi * cosLambda));
    x = b * cosPhi * sinLambda;
    y = b * (cosPhi0 * sinPhi - sinPhi0 * cosPhi * cosLambda);

    xy_out[i].even = x0 + scale * x;
    xy_out[i].odd  = y0 + scale * y;
}

__kernel void pl_unproject_lambert_azimuthal_equal_area_s(
    __global float16 *xy_in,
    __global float16 *xy_out,
    const unsigned int count,

    float scale,
    float x0,
    float y0,

    float phi0,
    float lambda0,

    float sinPhi0,
    float cosPhi0
) {
    int i = get_global_id(0);

    float8 x = (xy_in[i].even - x0) / scale;
    float8 y = (xy_in[i].odd - y0) / scale;

    float8 lambda, phi;

    float8 rho2;
    float8 sinC, cosC;

    rho2 = x*x + y*y;

    cosC = 1.f - 0.5f * rho2;
    sinC = sqrt(1.f - 0.25f * rho2); // actually, sin(c) / rho

    phi = asin(cosC * sinPhi0 + y * sinC * cosPhi0);
    lambda = atan2(x * sinC, cosPhi0 * cosC - y * sinPhi0 * sinC);

    xy_out[i].even = degrees(pl_mod_pi(lambda + lambda0));
    xy_out[i].odd = degrees(phi);
}
 
__kernel void pl_project_lambert_azimuthal_equal_area_e(
    __global float16 *xy_in,
    __global float16 *xy_out,
    const unsigned int count,

    float ecc,
    float ecc2,
    float one_ecc2,

    float scale,
    float x0,
    float y0,

    float phi0,
    float lambda0,
    float qp,
    float sinB1,
    float cosB1,

    float rq,
    float4 apa,
    float dd,
    float xmf,
    float ymf
) {
    int i = get_global_id(0);

    float8 lambda = radians(xy_in[i].even) - lambda0;
    float8 phi    = radians(xy_in[i].odd);

    float8 x, y;
    float8 b, sinLambda, cosLambda, sinPhi, sinB, cosB;

    sinLambda = sincos(lambda, &cosLambda);
    sinPhi = sin(phi);

    sinB = pl_qsfn(sinPhi, ecc, one_ecc2) / qp;
    cosB = sqrt(1.f - sinB * sinB);

    b = sqrt(2.f / (1.f + sinB1 * sinB + cosB1 * cosB * cosLambda));

    x = xmf * b * cosB * sinLambda;
    y = ymf * b * (cosB1 * sinB - sinB1 * cosB * cosLambda);

    xy_out[i].even = x0 + scale * x;
    xy_out[i].odd  = y0 + scale * y;
}

__kernel void pl_unproject_lambert_azimuthal_equal_area_e(
    __global float16 *xy_in,
    __global float16 *xy_out,
    const unsigned int count,

    float ecc,
    float ecc2,
    float one_ecc2,

    float scale,
    float x0,
    float y0,

    float phi0,
    float lambda0,
                                                          
    float qp,

    float sinB1,
    float cosB1,

    float rq,
    float4 apa,

    float dd,
    float xmf,
    float ymf
) {
    int i = get_global_id(0);

    float8 x = (xy_in[i].even - x0) / scale;
    float8 y = (xy_in[i].odd - y0) / scale;

    float8 lambda, phi;

    float8 cosCe, sinCe, rho2, beta;
        
    x /= dd;
    y *= dd;

    rho2 = (x*x + y*y) / rq / rq;

    cosCe = 1.f - 0.5f * rho2;
    sinCe = sqrt(1.f - 0.25f * rho2) / rq; // rather, sin(Ce) / rho

    beta = asin(cosCe * sinB1 + y * sinCe * cosB1);

    lambda = atan2(x * sinCe, cosB1 * cosCe - y * sinB1 * sinCe);
    
    phi = (beta + apa.s0 * sin(2.f * beta) + apa.s1 * sin(4.f * beta) + apa.s2 * sin(6.f * beta));
     
    xy_out[i].even = degrees(pl_mod_pi(lambda + lambda0));
    xy_out[i].odd = degrees(phi);
}

