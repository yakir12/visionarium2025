using WGLMakie
# using GLMakie
using CoordinateTransformations, Rotations

screen_config = (; resize_to=:parent)

WGLMakie.activate!(; screen_config...)

fig = Figure(size = (1000, 1000))

n = 101

ax = Axis3(fig[1, 1], aspect = :data, limits = ((-0.1, 1.2), (-1, 1), (-0.1, 1.2)))

sg = SliderGrid(
    fig[2, 1],
    (label = "Elevation", range = 0:90, format = "{:n}°", startvalue = 0),
    (label = "Error", range = 0:180, format = "{:n}°", startvalue = 0),
    tellwidth = false)

θdeg, ϵdeg = [s.value for s in sg.sliders]
θ, ϵ = [map(deg2rad, s.value) for s in sg.sliders]

sector = map(θ, ϵ) do θ, ϵ
    xyz = [zero(Point3f), Point3f.(CartesianFromSpherical().(Spherical.(1, range(-ϵ/2, ϵ/2, n - 2), 0)))..., zero(Point3f)]
    rot = LinearMap(RotY(-θ))
    rot.(xyz)
end
sectorc = @lift 0.9 * $sector[n ÷ 2 + 1]

shadow = map(x -> Point2f.(x), sector)
shadowc = @lift 0.9 * $shadow[n ÷ 2 + 1]

Εdeg = @lift round(Int, 2atand(tan($ϵ/2)/cos($θ)))

lines!(ax, sector, color = :black)
lines!(ax, shadow, color = :red)
# poly!(ax, Sphere(zero(Point3f), 0.025), color = :red)

sectorh = text!(ax, zero(Point3f), text = @lift(string($ϵdeg, " °")), color = :black, align = (:center, :center), markerspace = :data, fontsize = 0.1, transform_marker = true, overdraw = true)

sectorc0 = sectorc[]
on(sectorc) do sectorc
    quat = Makie.rotation_between(Vec3f(sectorc0), Vec3f(sectorc))
    Makie.rotate!(sectorh, quat)
    Makie.rotate!(Accum, sectorh, -pi/2)
    Makie.translate!(sectorh, sectorc...)
end

shadowh = text!(ax, zero(Point3f), text = @lift(string($Εdeg, " °")), color = :red, align = (:center, :center), markerspace = :data, fontsize = 0.1, transform_marker = true, overdraw = true)

shadowc0 = shadowc[]
on(shadowc) do shadowc
    quat = Makie.rotation_between(Vec3f(shadowc0..., 0), Vec3f(shadowc..., 0))
    Makie.rotate!(shadowh, -pi/2)
    Makie.translate!(shadowh, shadowc..., 0)
end

hidedecorations!(ax)

fig
