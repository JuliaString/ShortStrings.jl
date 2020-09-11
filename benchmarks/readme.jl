# short be
using SortingLab, ShortStrings, SortingAlgorithms, BenchmarkTools;
N = Int(1e6);
svec = [randstring(rand(1:15)) for i=1:N];
# convert to ShortString
ssvec = ShortString.(svec);
basesort = @benchmark sort($svec)
radixsort_timings = @benchmark SortingLab.radixsort($svec)
short_radixsort = @benchmark sort($ssvec, by = x->x.size_content, alg=RadixSort)

using RCall

@rput svec;
r_timings = R"""
replicate($(length(short_radixsort.times)), system.time(sort(svec, method="radix"))[3])
""";

using Plots
bar(["Base.sort","SortingLab.radixsort","ShortStrings radix sort", "R radix sort"],
    mean.([basesort.times./1e9, radixsort_timings.times./1e9, short_radixsort.times./1e9, r_timings]),
    title="String sort performance - len: 1m, variable size 15",
    label = "seconds")
savefig("readme_string_sort.png")


# short be
using SortingLab, ShortStrings, SortingAlgorithms, BenchmarkTools;
N = Int(2e7);
svec = rand([randstring(rand(1:15)) for i=1:N÷100],N)
# convert to ShortString
ssvec = ShortString.(svec);
basesort = @benchmark sort($svec) samples = 5 seconds = 120
radixsort_timings = @benchmark SortingLab.radixsort($svec) samples = 5 seconds = 120
short_radixsort = @benchmark sort($ssvec, by = x->x.size_content, alg=RadixSort) samples = 5 seconds = 120

using RCall

@rput svec;
r_timings = R"""
replicate(max(5, $(length(short_radixsort.times))), system.time(sort(svec, method="radix"))[3])
""";

using Plots
bar(["Base.sort","SortingLab.radixsort","ShortStrings radix sort", "R radix sort"],
    mean.([basesort.times./1e9, radixsort_timings.times./1e9, short_radixsort.times./1e9, r_timings]),
    title="String sort performance - len: $(N÷1_000_000)m, fixed size: 15",
    label = "seconds")
savefig("readme_string_sort_fixed_len.png")

N = 100_000_000
@time a = ShorterString.()

fsort(s) = sort(s, by = x->x.size_content, alg=RadixSort);
@time a_sorted = fsort(a);

ax = (x->x.size_content).(a)
@time sort(ax, alg=RadixSort);
