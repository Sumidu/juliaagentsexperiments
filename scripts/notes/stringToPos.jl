using Pkg



suffixeslist = "https://www.publicsuffix.org/list/public_suffix_list.dat"

using HTTP

res = HTTP.get(suffixeslist)
content = String(res.body)
lines = split(content, "\n")

filter!(x->!startswith(x, "/"), lines)
filter!(x->length(x)≠0, lines)
lines



reg = Regex(join(lines[1:200],"|"))

m = match(reg, url)
println(m)



urls = ["http://www.google.com/123",
        "https://www.google.de/1234",
        "https://docs.julialang.org/en/v1/manual/strings/",
        "https://stackoverflow.com/questions/21173734/extracting-top-level-and-second-level-domain-from-a-url-using-regex"
]

domainmatch = r"(?:https?:\/\/)?(?:www\.)?([^\/\r\n]+)(?:\/[^\r\n]*)"

dmatch = r"^(?:https?:\/\/)(?:w{3}\.)?.*?([^.\r\n\/]+\.)([^.\r\n\/]+\.[^.\r\n\/]{2,6}(?:\.[^.\r\n\/]{2,6})?).*$"


using URIParser

url = urls[1]
for url in urls
        u = URI(url)
        println(u)

end

u.host
u.path
u.port
u.query
u.scheme
u.specifies_authority

m = match(dmatch,u.host)
println(m)


using TextAnalysis, MultivariateStats, Clustering

crps = DirectoryCorpus("data/sotu")

standardize!(crps, StringDocument)

crps = Corpus(crps[1:30])

remove_case!(crps)
prepare!(crps, strip_punctuation)

update_lexicon!(crps)
update_inverse_index!(crps)

crps["freedom"]

m = DocumentTermMatrix(crps)

D = dtm(m, :dense)

T = tf_idf(D)

cl = kmeans(T, 5)

cl
