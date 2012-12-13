require_relative '../lib/lsh'

dim = 20 # Dimension
hash_size = 6 # Hash size (in bits for binary LSH)
window_size = Float::INFINITY # Binary LSH
n_projections = 5 # Number of independent projections
multiprobe_radius = 1 # Multiprobe radius (set to 0 to disable multiprobe)
fms_limit = 5 # Number of items to take into account in the k-NN for f-measure evaluation

index = LSH::Index.new(dim, hash_size, window_size, n_projections)

# Test dataset
vectors = []
1000.times { |i| vectors << index.random_vector(dim) } 

# Adding to index
vectors.each { |v| index.add(v) }

# Nearest neighbors in query result?
bf_times = []
lsh_times = []
scores = []
sizes = []
fms_scores = []
vectors.each_with_index do |vector, i|
  t0 = Time.now
  similar_vectors = index.order_vectors_by_similarity(vector, vectors)
  t1 = Time.now
  results = index.query(vector, multiprobe_radius)
  t2 = Time.now
  sizes << results.size
  $stderr.puts "#{results.size} results for vector #{i}"
  k = 0
  while k < results.size and results[k] == similar_vectors[k]
    k += 1
  end
  scores << k
  $stderr.puts "Nearest neighbours up to #{k} appear in results"
  if results.size > 1
    $stderr.puts "Distance of first result: #{results[1] * vector.col}"
  end
  $stderr.puts "Distance of first missed nearest neighour: #{similar_vectors[k] * vector.col}"
  $stderr.puts "Time for brute-force search: #{t1 - t0}"
  bf_times << t1 - t0
  $stderr.puts "Time for LSH search: #{t2 - t1}"
  lsh_times << t2 - t1
  precision = 0.0
  recall = 0.0
  results.first(fms_limit).each { |r| (precision += 1; recall += 1) if similar_vectors.first(fms_limit).member?(r) }
  precision /= results.first(fms_limit).size
  recall /= similar_vectors.first(fms_limit).size
  fms = 2 * (precision * recall) / (precision + recall)
  $stderr.puts "F-Measure for #{fms_limit}-NN: #{fms}"
  fms_scores << fms
end

avg_size = 0.0
sizes.each { |s| avg_size += s }
avg_size /= sizes.size
$stderr.puts "Average number of results: #{avg_size}"

p = 0.0
scores.each { |s| p += 1 if s > 1 }
p /= scores.size.to_f
$stderr.puts "Probability of nearest neighbour (not self) being in results: #{p}"

nn = 0.0
scores.each { |s| nn += s }
nn /= scores.size.to_f
$stderr.puts "Average number of nearest neighbours in results: #{nn}"

avg_fms = 0.0
fms_scores.each { |s| avg_fms += s }
avg_fms /= fms_scores.size.to_f
$stderr.puts "Average F-Measure score: #{avg_fms}"

avg_bf_time = 0.0
bf_times.each { |t| avg_bf_time += t }
avg_bf_time /= bf_times.size
$stderr.puts "Average brute-force search time: #{avg_bf_time}"

avg_lsh_time = 0.0
lsh_times.each { |t| avg_lsh_time += t }
avg_lsh_time /= lsh_times.size
$stderr.puts "Average LSH search time: #{avg_lsh_time}"
