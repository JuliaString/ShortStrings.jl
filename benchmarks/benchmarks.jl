using ShortStrings, SortingAlgorithms, BenchmarkTools, SortingLab, DataFrames, CSV
N = 100_000_000; K=100;
using Plots
using StatPlots, RCall

function string_sort_perf(N, K)
    tic()
    ss ="id".*dec.(1:N÷K,10);
    srand(1);
    ss1 = rand(ss, N);
    svec = ShortString.(ss1);

    rs = @benchmark sort($svec, by = x->x.size_content, alg = RadixSort) samples = 5

    rs1 = @benchmark SortingLab.radixsort($ss1) samples = 5

    @rput ss1
    r_times = R"""
    memory.limit(2^31-1)
    replicate(max(5, $(length(rs.times))), system.time(sort(ss1, method="radix"))[3])
    """

    df = DataFrame(xlabel = ["Julia - Strings", "Julia - ShortStrings", "R"], timing = mean.([rs1.times/1e9, rs.times./1e9, r_times]))
    CSV.write("String sort perf $(N÷1_000_000)m.csv", df)
    gb = bar(
        df[:xlabel],
        df[:timing],
        title = "String sort perf $(N÷1_000_000)m",
        label="seconds"
        )
    savefig(gb, "String sort perf $(N÷1_000_000)m.png")
    toc()
end

string_sort_perf(100, 100) # warm up

@time string_sort_perf.((1:10).*10^8, 100)