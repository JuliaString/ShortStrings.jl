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