# SIFKit.jl 📦: A andor sif analysis tools in Julia





📦 **SIFKit.jl** is a Julia package for parsing Andor `.sif` camera files and providing tools for spectra analysis and data inspection.

## 📦 Features

- Efficient `.sif` binary parsing
- Easy access to image stacks, dimensions, metadata
- Spectrum data extraction and analysis tools

## 🧪 Installation

In julia REPL, type

```julia REPL
] add SIFKit
```
## 🚀 Usage

```julia
sifImage = load(test_siffile)
@show size(sifImage.data)      # (width, height, frames)
@show sifImage.metadata["ExposureTime"]  # exposure time

waveLengths = SIFKit.retrieveCalibration(sifImage.metadata)

xlabel = ""

"""
 for Imaging data,
@show metadata["ImageAxis"]
xlabel = metadata["ImageAxis"] == "Wavelength" ? "Wavelength (nm)" : "Pixels"
and do heatmap
hm = heatmap!(ax, imageData, colorrange = (635, 670))

"""

@show sifImage.metadata["FrameAxis"]
isRaman = sifImage.metadata["FrameAxis"] == "Raman shift"


if isRaman
    RamanExcitation = sifImage.metadata["RamanExWavelength"]
    RamanShift = Wavelength2Raman.(RamanExcitation, waveLengths)
    xlabel = rich("$(sifImage.metadata["FrameAxis"]) (cm", superscript("-1"), ")")
else
    xlabel = sifImage.metadata["FrameAxis"]*" (nm)"
end
    

using CairoMakie

f = Figure(size = (800,500), fontsize = 22)
    
ax = Axis(f[1,1], 
            xlabel = xlabel,
            ylabel = "Counts",
            xticks = isRaman ? (-400:400:2500) : (500:20:700),
            xlabelsize = 28,
            ylabelsize = 28,
            xgridvisible = false,
            ygridvisible = false)

data = dropdims(sifImage.data, dims = (2,3)) # assume single frame

lines!(ax, isRaman ? RamanShift : waveLengths, data, color=:dodgerblue3, label="Frame 1")

save("_makie.png", f, px_per_inch = 10)

display(f) # wait(display(f)) if you use GLMakie and a pop-out window

# what a nice spectrum!
```
<img src="./test/neon_rows_138to150_after_x_calibration_3_makie.png" alt="Description" width="750"/>

If you or your collaborators like txt files better, then do

```julia

Export2Txt(sif_data, "_data.txt")

# then output a _data.txt containing metadata and data

```

## 🔧 Developer Notes


Clean and re-precompile

```bash
rm -rf ~/.julia/compiled/v1.10/SIFKit

julia --project=.

] add APackage (dependency in the package => update project.toml by adding APackage)

] precompile 

] test (run test/runtests.jl)
```

## 🤝 Contributing
Contributions and issues are welcome! Please open a PR or submit an issue if you run into any bugs or have feature requests.

## 📜 License
MIT License. 
