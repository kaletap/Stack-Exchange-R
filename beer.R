#source("df_from_xml.R")
options(stringsAsFactors = FALSE)

Comments <- read.csv("data/beer.stackexchange.com/Comments.csv")
Badges <- read.csv("data/beer.stackexchange.com/Badges.csv")
PostsHistory <- read.csv("data/beer.stackexchange.com/PostHistory.csv")
Posts <- read.csv("data/beer.stackexchange.com/Posts.csv")
Users <- read.csv("data/beer.stackexchange.com/Users.csv")
Tags <- read.csv("data/beer.stackexchange.com/Tags.csv")
Votes <- read.csv("data/beer.stackexchange.com/Votes.csv")

#biblioteki
library(stringi)
library(tidytext)
library(dplyr)
library(maps)
library(tidytext)
library(tm)
library(wordcloud)
library(qdap)
library(RWeka)
library(wesanderson)
library(reshape2)
library(ggplot2)
library(textstem)
#Histogramy
Votes_czas <- data.frame(date = as.numeric(format(as.Date(Votes$CreationDate, "%Y"),"%Y"))) %>% group_by(date) %>%
  summarise(liczba = n())
Posts_czas <- data.frame(date = as.numeric(format(as.Date(Posts$CreationDate, "%Y"),"%Y"))) %>% group_by(date) %>%
  summarise(liczba = n() )
Comments_czas <- data.frame(date = as.numeric(format(as.Date(Comments$CreationDate, "%Y"),"%Y"))) %>% group_by(date) %>%
  summarise(liczba = n())

czas_all <- cbind(rbind(Votes_czas,Posts_czas,Comments_czas), typ = c(rep("votes",nrow(Votes_czas)),
                                                                      rep("Posts",nrow(Posts_czas)),
                                                                      rep("Comments",nrow(Comments_czas))))

ggplot(czas_all, aes(x = date,y = liczba,fill = typ)) + geom_bar(stat="identity",position='dodge') 

#frequency word plot
#comments
frequency <- freq_terms(Comments$Text, top = 10, stopwords = stopwords("en"))
plot(frequency)
#posts
frequency <- freq_terms(Posts$Body, top = 10, stopwords = stopwords("en"))
plot(frequency)


#text-mining

clean_text <- function(text){
  text <- lemmatize_strings(text)
  text <- removePunctuation(text)
  text <- tolower(text)
  text <- removeWords(text,stopwords("en"))
  text <- stripWhitespace(text)
  text
}


###########KOMENTARZE
# comment_clean <- clean_text(Comments$Text)
# 
# comment_list <- as.list(comment_clean)
# comment_list <- lapply(comment_list,stri_extract_all_regex, "[a-z]+")
# comment_list <- lapply(comment_list,function(x){
#   x <- data.frame(word = x)
#   colnames(x) <- "word"
#   x
# })
# 
# list <- lapply(comment_list, function(x){
#   x %>%
#     inner_join(data.frame(get_sentiments("nrc")),by = "word") %>%
#     group_by(sentiment) %>% count(sentiment, sort = TRUE) %>% as.data.frame() %>% top_n(1)
# })
# 
# from_df_to_vector <- function(x){
#   vec <- x[,2]
#   names(vec) <- x[,1]
#   vec
# }
# 
# sentiment_vector <- unlist(lapply(list, from_df_to_vector))
# 
# #emocje
# df_sentiment <- data.frame(moc = sentiment_vector, emocja = names(sentiment_vector))
# df_sentiment <- df_sentiment %>% group_by(emocja) %>%
#   summarise(suma = sum(moc), liczba_komentarzy = n())
# df_sentiment$suma = df_sentiment$suma/(sum(df_sentiment$suma))
# df_sentiment$liczba_komentarzy = df_sentiment$liczba_komentarzy/(sum(df_sentiment$liczba_komentarzy))
# 
# 
# df_sentiment <- melt(df_sentiment,id.vars = "emocja")
# df_sentiment <- df_sentiment[11:20,]
# saveRDS(df_sentiment,"df_sentiment_beer.rds")

df_sentiment <- readRDS("df_sentiment_beer.rds")
ggplot(df_sentiment,aes(x = reorder(emocja,-value), y = value, fill = variable)) + geom_bar(stat="identity",position='dodge') +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) + xlab("emocje") + labs(title = "Rozk�ad emocji w komentarzach")

# #POSTY
# comment_clean <- clean_text(Posts$Body)
# 
# comment_list <- as.list(comment_clean)
# comment_list <- lapply(comment_list,stri_extract_all_regex, "[a-z]+")
# comment_list <- lapply(comment_list,function(x){
#   x <- data.frame(word = x)
#   colnames(x) <- "word"
#   x
# })
# 
# list <- lapply(comment_list, function(x){
#   x %>%
#     inner_join(data.frame(get_sentiments("nrc")),by = "word") %>% 
#     group_by(sentiment) %>% count(sentiment, sort = TRUE) %>% as.data.frame() %>% top_n(1)
# })
# 
# from_df_to_vector <- function(x){
#   vec <- x[,2]
#   names(vec) <- x[,1]
#   vec
# }
# 
# sentiment_vector <- unlist(lapply(list, from_df_to_vector))
# 
# 
# #emocje
# df_sentiment <- data.frame(moc = sentiment_vector, emocja = names(sentiment_vector))
# df_sentiment <- df_sentiment %>% group_by(emocja) %>%
#   summarise(suma = sum(moc), liczba_postow = n())
# 
# df_sentiment$suma = df_sentiment$suma/(sum(df_sentiment$suma))
# df_sentiment$liczba_postow = df_sentiment$liczba_postow/(sum(df_sentiment$liczba_postow))
# 
# 
# df_sentiment <- melt(df_sentiment,id.vars = "emocja")
# df_sentiment <- df_sentiment[11:20,]
# df_sentiment$variable <- "beer"
# 
# saveRDS(df_sentiment,"df_sentiment_beer_post.rds")

df_sentiment <- readRDS("df_sentiment_beer_post.rds")
ggplot(df_sentiment,aes(x = reorder(emocja,-value), y = value, fill = variable)) + geom_bar(stat="identity",position='dodge') +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) + xlab("emocje") + labs(title = "Rozk�ad emocji w tresci postow")


########CZESTO UZYWANE SLOWA
###KOMENTARZE
#positive
pos_comment <- unnest_tokens(tbl = Comments,input = Text, output = word,to_lower = TRUE)[,c("Score","word","Id")] %>% 
  inner_join(get_sentiments("bing")) %>% filter(sentiment == "positive") %>% group_by(word) %>% summarise(count = n()) %>% 
  arrange(desc(count))

#negative
neg_comment <- unnest_tokens(tbl = Comments,input = Text, output = word,to_lower = TRUE)[,c("Score","word","Id")] %>% 
  inner_join(get_sentiments("bing")) %>% filter(sentiment == "negative") %>% group_by(word) %>% summarise(count = n()) %>% 
  arrange(desc(count))

top_neg <- data.frame(count = -neg_comment$count[1:10],word = neg_comment$word[1:10])
top_pos <- pos_comment[1:10,]

top_word <- top_neg %>% union(top_pos) %>% arrange(count) %>% mutate(grupa = as.factor(sign(count)))

ggplot(top_word, aes(x = reorder(word,count), y = count, fill = grupa)) + geom_bar(stat="identity",position='dodge') + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) + xlab("word") + 
  scale_fill_brewer(type = "seq",palette = "Set1") +
  theme(legend.position="none") + labs(title = "Najczesciej uzywane pozytywne i negatywne slowa")


###POSTY
#positive
pos_post <- unnest_tokens(tbl = Posts,input = Body, output = word,to_lower = TRUE)[,c("Score","word","Id")] %>% 
  inner_join(get_sentiments("bing")) %>% filter(sentiment == "positive") %>% group_by(word) %>% summarise(count = n()) %>% 
  arrange(desc(count))

#negative
neg_post <- unnest_tokens(tbl = Posts,input = Body, output = word,to_lower = TRUE)[,c("Score","word","Id")] %>% 
  inner_join(get_sentiments("bing")) %>% filter(sentiment == "negative") %>% group_by(word) %>% summarise(count = n()) %>% 
  arrange(desc(count))

top_neg_post <- data.frame(count = -neg_post$count[1:10],word = neg_post$word[1:10])
top_pos_post <- pos_comment[1:10,]

top_word_post <- top_neg_post %>% union(top_pos_post) %>% arrange(count) %>% mutate(grupa = as.factor(sign(count)))

ggplot(top_word_post, aes(x = reorder(word,count), y = count, fill = grupa)) + geom_bar(stat="identity",position='dodge') + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) + xlab("word") + 
  scale_fill_brewer(type = "seq",palette = "Set1") +
  theme(legend.position="none") + labs(title = "Najczesciej uzywane pozytywne i negatywne slowa")



#polarity
# 
# polarity_comments <-  polarity(
#   text.var       = Comments$Text,
#   grouping.var   = Comments$Id,
#   polarity.frame = key.pol,
#   negators       = negation.words,
#   amplifiers     = amplification.words,
#   deamplifiers   = deamplification.words 
# )
# 
# 
# 
# polarity_by_posts <-  polarity(
#   text.var       = Comments$Text,
#   grouping.var   = Comments$PostId,
#   polarity.frame = key.pol,
#   negators       = negation.words,
#   amplifiers     = amplification.words,
#   deamplifiers   = deamplification.words 
# )
# 
# 
# polarity_by_user <-  polarity(
#   text.var       = Comments$Text,
#   grouping.var   = Comments$UserId,
#   polarity.frame = key.pol,
#   negators       = negation.words,
#   amplifiers     = amplification.words,
#   deamplifiers   = deamplification.words 
# )
# 
# 
# polarity <- data.frame(polarity = c(polarity_comments$group$ave.polarity,polarity_by_posts$group$ave.polarity,
#                                     polarity_by_user$group$ave.polarity), by = c(rep("comment_ID",
#                                                                                      length(polarity_comments$group$ave.polarity)),
#                                                                                  rep("post",
#                                                                                      length(polarity_by_posts$group$ave.polarity)),
#                                                                                  rep("user",
#                                                                                      length(polarity_by_user$group$ave.polarity))))

#saveRDS(polarity,"polarity_beer.rds")

polarity <- readRDS("polarity_beer.rds")
ggplot(polarity,aes(y = polarity, x = by, color = by)) + geom_boxplot(outlier.colour="black", outlier.shape=16,
                                                                      outlier.size=2,outlier.alpha = 0.1)


#word cloud
clean_corpus <- function(corpus) {
  corpus <- tm_map(corpus, removePunctuation)
  corpus <- tm_map(corpus, content_transformer(tolower))
  corpus <- tm_map(corpus, removeWords, c(stopwords("en"),"coffee"))
  corpus <- tm_map(corpus, stripWhitespace)
  return(corpus)
}

Comm_corp <- VCorpus(VectorSource(Comments$Text))
Comm_corp <- clean_corpus(Comm_corp)

tdm_comm <- as.matrix(TermDocumentMatrix(Comm_corp))
freq_word <- rowSums(tdm_comm)
freq_word <- sort(freq_word, decreasing = TRUE)

wordcloud(names(freq_word),freq_word ,max.words = 20, col = "tan")
title("Wordcloud slow w tekscie komentarzy")

Post_corp <- clean_corpus(VCorpus(VectorSource(Posts$Body)))
tdm_post <- as.matrix(TermDocumentMatrix(Post_corp))
freq_word_post <- sort(rowSums(tdm_post), decreasing = TRUE)

wordcloud(names(freq_word_post),freq_word_post ,max.words = 20, col = "tan")
title("Wordcloud slow w tekscie postow")

#BIGRAMY


#komentarze
tokenizer <- function(x){
  NGramTokenizer(x, Weka_control(min=2, max = 2) )
}

bigram_dtm_comm <- as.matrix(TermDocumentMatrix(Comm_corp,control = list(tokenize = tokenizer) ))
bigram_freq_comm <- sort(rowSums(bigram_dtm_comm), decreasing = TRUE)

wordcloud(names(bigram_freq_comm),bigram_freq_comm,max.words = 20, col = "tan")
title("Wordcloud bigramow w tekscie komentarzy")

#tresc postow
bigram_dtm_post <- as.matrix(TermDocumentMatrix(Post_corp,control = list(tokenize = tokenizer) ))
bigram_freq_post <- sort(rowSums(bigram_dtm_post), decreasing = TRUE)

wordcloud(names(bigram_freq_post),bigram_freq_post,max.words = 20, col = "tan")
title("Wordcloud bigramow w tekscie postow")


#POPULARNOSC RODZAJOW KAWY
#komentarze

popular_beer <- c("lager","pilsner","porter","stout","wheat", "ipa","apa","hefeweizen","bock")

clean_coments <- lapply(Comm_corp, "[",1)
beer_type_comm <- lapply(clean_coments, stri_detect_fixed, popular_beer)
beer_type_comm <- as.data.frame(t(as.data.frame(beer_type_comm)))
colnames(beer_type_comm) <- popular_beer
sum_beer_type_comm <- colSums(beer_type_comm)

sum_beer_type_comm

#tresc postow
clean_posts_body <- lapply(Post_corp, "[",1)
beer_type_posts_body <- lapply(clean_posts_body, stri_detect_fixed, popular_beer)
beer_type_posts_body <- as.data.frame(t(as.data.frame(beer_type_posts_body)))
colnames(beer_type_posts_body) <- popular_beer
sum_beer_type_posts <- colSums(beer_type_posts_body)

df_beer_type <- data.frame(count = c(sum_beer_type_comm,sum_beer_type_posts), type = c(rep("comm",length(popular_beer)),
                                                                                       rep("body post",length(popular_beer))),
                             beer =  rep(popular_beer,2))

ggplot(df_beer_type,aes(y = count, x = reorder(beer,-count), fill = type)) +
  geom_bar(stat="identity",position=position_dodge()) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  scale_fill_brewer(type = "seq",palette = "OrRd") +
  geom_text(aes(label=count), vjust=1.6, color="black",
            position = position_dodge(0.9), size=3.5) + xlab("beer type") + labs("Popularnosc rodzajow piwa")
