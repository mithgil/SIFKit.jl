

using SIFKit, Test


"""
Generate a small test SIF file (valid or invalid)
"""
function generate_test_sif(path::String; valid::Bool = true)
    open(path, "w") do io
        if valid
            write(io, b"Andor Technology Multi-Channel File\x0a")  # magic header
            write(io, "65538 1\x0a")                                # version line
            write(io, "0.1 1.0\x0a")                                # dummy metadata
            write(io, rand(Float32, 3*3*2))                         # 3x3x2 float data
        else
            write(io, "INVALID FILE CONTENT")
        end
    end
end

"""
Generate a large test SIF file to test memory efficiency
"""

function generate_large_test_sif(desPath::String, frameNumber::Int32, sourcePath::String)

    sifdata = load(sourcePath)
    byte_limit = sifdata.metadata["offset"]
    dims = sifdata.metadata["DetectorDimensions"]

    open(sourcePath, "r") do src
        open(desPath, "w") do dest
            buf = read(src, byte_limit-1)  
            write(dest, buf)             
            
            testframeNum = frameNumber
            write(dest, rand(Float32, dims[1], 1, testframeNum))
        end
    end

end

@testset "Andor SIF Loader Tests" begin

    testSif = "neon_rows_138to150_after_x_calibration_3.sif"
    # === test a normal file ===
    test_path = joinpath(@__DIR__, testSif)
    
    @testset "Valid File Loading" begin
        sif_data = load(test_path)
        
        # test returned data type
        @test sif_data isa SIFData
        
        # test metadata
        @test haskey(sif_data.metadata, "DetectorDimensions")
        @test sif_data.metadata["DetectorDimensions"] isa Tuple{Int, Int}
        @test sif_data.metadata["FrameAxis"] in ["Raman shift", "Wavelength"]
        # test data shape
        @test size(sif_data.data) isa Tuple{Int, Int, Int}
        # test calibration data
        @test haskey(sif_data.metadata, "Calibration_data");
        
    end

    # === test invalid files ===
    @testset "Invalid Files" begin
        # invalid versions
        invalid_version = joinpath(@__DIR__, "test_invalid_version.sif")
        open(invalid_version, "w") do io
            write(io, b"Andor Technology Multi-Channel File\x0a")
            write(io, "123 456\x0a")  # 错误的版本号
        end
        @test_throws "Unknown Andor version" load(invalid_version)
        rm(invalid_version)

        # empty
        empty_file = joinpath(@__DIR__, "test_empty.sif")
        touch(empty_file)
        @test_throws Exception load(empty_file)
        rm(empty_file)

        # non-sif
        not_sif = joinpath(@__DIR__, "test_not_sif.txt")
        open(not_sif, "w") do io
            write(io, "This is not a SIF file")
        end
        @test_throws Exception load(not_sif)        # 清理测试文件

        rm(not_sif)
    end

    @testset "Memory Allocation Check for Large File" begin
        desc_path = joinpath(@__DIR__, "large_test.sif")
        source_path = test_path
        generate_large_test_sif(desc_path, Int32(250_000), source_path)  

        # Check that `load()` is reasonably efficient (<1MB allocation allowed here)
        alloc = @allocated load(desc_path)
        @test alloc < 1_000_000  # adjust threshold as needed

        rm(desc_path, force=true)
    end

    @testset "Valid File Exporting" begin
        sif_data = load(test_path)
        
        # test returned data type
        @test sif_data isa SIFData
        
        @test size(sif_data.data) isa Tuple{Int, Int, Int}

        # Call the function to perform the export
        Export2Txt(sif_data, "_test_exported_data.txt")

        # Now, test the side effect: check if the file exists
        @test isfile("_test_exported_data.txt")

        content = readlines("_test_exported_data.txt")

        @test length(content) > 0
        @test startswith(content[1], "# ------ METADATA ------")

        rm("_test_exported_data.txt")
    end

        

end
