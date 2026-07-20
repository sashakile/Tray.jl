using Tray
using ReTestItems
using Test

@testitem "scaffold greeting" begin
    using Tray

    @test isnothing(redirect_stdout(devnull) do
        Tray.greet()
    end)

    output = Pipe()
    redirect_stdout(output) do
        Tray.greet()
    end
    close(Base.pipe_writer(output))
    @test read(output, String) == "Hello World!"
end
