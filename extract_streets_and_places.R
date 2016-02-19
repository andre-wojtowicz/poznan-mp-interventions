require(gdata)
require(vwr)

DB_INPUT_FILE_PATH    = "db/poznan-mp-interventions-2013-06-17-2013-10-09.csv"
DB_OUTPUT_DIR_NAME    = "gen"
DB_OUTPUT_FILE_NAME   = "parsed-poznan-mp-interventions-2013-06-17-2013-10-09.csv"
DB_STREETS_AND_PLACES_FILE_NAME = "db/poznan-streets-and-places.csv"

DB_OUTPUT_SIZE = -1 # how many interventions to parse; below 0 means all
MAX_N_GRAM = 5 # maximum number of consecutive words from a description of an intervention that should be parsed

#____________________________________________________________

#descriptions of interventions without meaningful description - to remove from db
SKIP_TXT = c("[POTWIERDZENIE] ZG£OSZENIE S",
             "***SPAM*** [POTWIERDZENIE] ZG£OSZE")

#descriptions of interventions which are not informative - popular in db, don't have address; also should be removed
DONT_PARSE_TXT = c("parkowanie",
                   "monitoring",
                   "alkohol",
                   "spo¿ywanie alkoholu")

#streets or places which should be perfectly matched by levenshtein distance measure (high probability of error matching)
PERFECT_MATCH = tolower(c("A2",
                          "Dojazd",
                          "Pomarañczowa",
                          "Kopy",
                          "Luba",
                          "AK",
                          "Burzowa",
                          "Piwna",
                          "Soko³a",
                          "Reja",
                          "Œwit",
                          "Górki",
                          "strzelca",
                          "G³adka",
                          "Zachodnia",
                          "Krótka",
                          "Otwarta",
                          "Panny",
                          "Drzewna",
                          "Jasna",
                          "Dêbiñski"))

#phrases from descriptions of interventions which might be incorrectly matched to streets or names
IGNORED_PHRASES = c("studzienka",
                    "studzienka burzowa",
                    "sygnalizacja œwietlna",
                    "sygn. œwietlna",
                    "kratka burzowa",
                    "g³oœna muzyka",
                    "padlina go³êbia",
                    "otwarta studzienka",
                    "otwarta gablota")

#words to ignore if they are not at the beginning of a description
ONLY_AT_BEGINNIG = c("dojazd")

#maximal number of a house in a street
MAX_STREET_NUMBER = 500

#____________________________________________________________

# loads interventions and build combinations of names of streets and places
load_data = function()
{
    cat(sprintf("Loading interventions...\n"))
    
    db_input = read.csv(DB_INPUT_FILE_PATH)
    
    cat(sprintf("Loading streets and places...\n"))
    
    db_streets = read.csv(DB_STREETS_AND_PLACES_FILE_NAME, header=FALSE)
    colnames(db_streets) = c("type", "name_1", "name_2", "name_3")
    db_streets_to_out = db_streets # preserve street names with national letters
    db_streets$name_1 = tolower(db_streets$name_1)
    db_streets$name_2 = tolower(db_streets$name_2)
    db_streets$name_3 = tolower(db_streets$name_3)
    
    dict_streets = list() # list of possible names of streets and places, given by the lenght
    for (i in 1:MAX_N_GRAM)
        dict_streets[[i]] = data.frame(ngram  = character(),
                                       id_ref = numeric())
    
    # generate combinations of names without national letters
    for (i in 1:dim(db_streets)[1])
    {
        type   = as.character(db_streets[i,]$type)
        name_1 = as.character(db_streets[i,]$name_1)
        name_2 = as.character(db_streets[i,]$name_2)
        name_3 = as.character(db_streets[i,]$name_3)
        
        types = type
        if (type=="al.") types = c(type, "aleje") # add meanings of abbreviations
        if (type=="ul.") types = c(type, "ulica")
        if (type=="pl.") types = c(type, "plac")
        if (type=="os.") types = c(type, "osiedle")
        
        for (type in types)
            for (name in unique(c(name_1, name_2, name_3)))
                for (key in c(paste(type, name), name))
                {
                    key = strsplit(key, "[[:^alnum:]]", perl=TRUE)[[1]]    
                    key = key[key != ""]
                    key = paste(key, collapse=" ")
                    
                    key = iconv(key, "cp1250", "ASCII//TRANSLIT")
                    
                    new_row = data.frame(ngram  = key,
                                         id_ref = i)
                    
                    len = length(strsplit(key, " ")[[1]])
                        
                    dict_streets[[len]] = rbind(dict_streets[[len]], new_row)
                }
        
        if (i%%5==0)
            cat(sprintf("%.0f %%\r", i/dim(db_streets)[1]*100))
        
    }
    
    cat(sprintf("\n...OK\n"))
    
    return (list(db_input, db_streets, dict_streets, db_streets_to_out))
}

#____________________________________________________________

#splits words and numbers without space, interprets abbrevations
correct_tokens = function(tokens)
{
    ret = c()

    #split words and numbers without space
    for (token in tokens)
    {
        if (!(token %in% c("M1", "A2")))
            token = sub("([[:alpha:]]+)([[:digit:]]+)", "\\1 \\2", token, perl=TRUE)
        
        token = sub("([[:digit:]]+)([[:alpha:]]+)", "\\1 \\2", token, perl=TRUE)
        
        token = sub("([[:digit:]]+)([[:alpha:]]+)([[:digit:]]+)", "\\1 \\2 \\3", token, perl=TRUE)
        token = sub("([[:alpha:]]+)([[:digit:]]+)([[:alpha:]]+)", "\\1 \\2 \\3", token, perl=TRUE)
        
        for (t in strsplit(token, " ")[[1]])
            ret = c(ret, t)
    }
    tokens = ret; ret = c()
    
    #add space after street prefix 'ul' (quite common in db)
    for (token in tokens)
    {
        token = sub("^(ul)([[:alnum:]]+)", "\\1 \\2", token, perl=TRUE)
    
        for (t in strsplit(token, " ")[[1]])
            ret = c(ret, t)
    }
    tokens = ret; ret = c()
    
    #interpret abbreviations
    for (token in tokens)
    {
        tmp = tolower(token)
        
        if (tmp == "ww" || tmp == "oww")
            token = "os. Wichrowe Wzgórze"
        else if (tmp == "osb")
            token = "os. Stefana Batorego"
        else if (tmp == "ow³")
            token = "os. W³adys³awa £okietka"
        else if (tmp == "oz")
            token = "os. Zodiak" #or might be os. Zwyciestwa...
        
        for (t in strsplit(token, " ")[[1]])
            ret = c(ret, t)
    }
    
    
    return (ret)
}

#____________________________________________________________

#format of output interventions data
db_output = data.frame(id             = numeric(),
                       date           = character(),
                       time           = character(),
                       category       = character(),
                       description    = character(),
                       department     = character(),
                       district       = character(),
                       street1_ref_id = character(), # ref_id is a number of a row in db_streets
                       street1_prefix = character(),
                       street1_name   = character(),
                       street1_number = character(),
                       street2_ref_id = character(),
                       street2_prefix = character(),
                       street2_name   = character(),
                       street2_number = character(),
                       street3_ref_id = character(),
                       street3_prefix = character(),
                       street3_name   = character(),
                       street3_number = character(),
                       lat            = character(),
                       lon            = character())

#extracts streets and places from descriptions of interventions
extracts_streets_and_places = function(db_output_size)
{    
    if (db_output_size <= 0)
        db_output_size = dim(db_input)[1]
    
    cat(sprintf("Extracting streets and places...\n"))
    
    for (i in 1:db_output_size)
    {
        date_and_time = strsplit(as.character(db_input[i,2]), " ")[[1]]
        
        if (as.character(db_input[i,5]) %in% SKIP_TXT)
            next
        
        txt = split_txt_intervention(as.character(db_input[i,5]))
        
        new_row = data.frame(id             = as.numeric(db_input[i,1]),
                             date           = date_and_time[1],
                             time           = date_and_time[2],
                             category       = as.character(db_input[i,3]),
                             description    = as.character(txt$description),
                             department     = as.character(db_input[i,4]),
                             district       = "",
                             street1_ref_id = as.character(txt$street1_ref_id),
                             street1_prefix = as.character(txt$street1_prefix),
                             street1_name   = as.character(txt$street1_name),
                             street1_number = as.character(txt$street1_number),
                             street2_ref_id = as.character(txt$street2_ref_id),
                             street2_prefix = as.character(txt$street2_prefix),
                             street2_name   = as.character(txt$street2_name),
                             street2_number = as.character(txt$street2_number),
                             street3_ref_id = as.character(txt$street3_ref_id),
                             street3_prefix = as.character(txt$street3_prefix),
                             street3_name   = as.character(txt$street3_name),
                             street3_number = as.character(txt$street3_number),
                             lat            = "",
                             lon            = "")
        
        db_output <<- rbind(db_output, new_row) # assign to global variable
        
        if (i%%2==0)
            cat(sprintf("%.0f %%\r", i/db_output_size*100))
    }
    
    cat(sprintf("\n...OK\n"))
}

#processes a description of an intervention
split_txt_intervention = function(txt)
{
    
    description    = ""
    street1_ref_id = ""
    street1_prefix = ""
    street1_name   = ""
    street1_number = ""
    street2_ref_id = ""
    street2_prefix = ""
    street2_name   = ""
    street2_number = ""
    street3_ref_id = ""
    street3_prefix = ""
    street3_name   = ""
    street3_number = ""
    
    if (tolower(txt) %in% DONT_PARSE_TXT)
    {
        description = txt
    }
    else
    {
        matchings = c()
        matchings_numpos = list()
        
        for (p in IGNORED_PHRASES)
            txt = sub(paste("(.*)",p,"(.*)", sep=""), "\\1 \\2", txt, perl=TRUE)
        
        tokens = strsplit(txt, "[[:^alnum:]]", perl=TRUE)[[1]]    
        tokens = tokens[tokens != ""]
        
        tokens = correct_tokens(tokens)
        tokens = tolower(tokens)
        
        i = 1
        while (i <= length(tokens)) # move through positions of tokens...
        {
            jump = FALSE
            jump_step = 0
            
            for (j in MAX_N_GRAM:1) #...and check n-grams
            {
                if (i+j-1 > length(tokens))
                    next
                
                ngram = tokens[i:(i+j-1)]
                ngram_txt = paste(ngram, collapse=" ")
                ngram_txt = iconv(ngram_txt, "cp1250", "ASCII//TRANSLIT") #ignore national letters
                ngram_len = length(ngram)
                
                ngram_dists = levenshtein.distance(ngram_txt, dict_streets[[ngram_len]]$ngram) # calc. levenshtein distance to street names
                
                ngram_min_dist = as.numeric(min(ngram_dists)) # get the lowest distance...
                ngram_min_name = names(which.min(ngram_dists)) # ...and its street name...
                ngram_min_id_ref = dict_streets[[ngram_len]][which.min(ngram_dists),]$id_ref # ...and id number in db_streets
                
                if (max(db_streets[ngram_min_id_ref,c(2:4)] %in% PERFECT_MATCH) == 1 && ngram_min_dist > 0) # ignore if not perfectly matched
                    next
                
                if (max(db_streets[ngram_min_id_ref,c(2:4)] %in% ONLY_AT_BEGINNIG) == 1 && i >= 3) # ignore if matching is not at the beginning of the description
                    next
                
                #debugging stuff
#                 cat(sprintf("  [%.0f] %s - %s (%.0f)\n",
#                             ngram_min_dist,
#                             ngram_txt,
#                             ngram_min_name,
#                             ngram_min_id_ref
#                             )
#                 )
                
                # if distance is low then assume its good matching and move on
                if (ngram_min_dist <= 1)
                {
                    matchings = c(matchings, as.numeric(ngram_min_id_ref))
                    matchings_numpos = c(matchings_numpos, list(c(i, i+j)))
                    jump = TRUE
                    jump_step = j
                    break
                }
            }
            if (jump)
                i = i+jump_step
            else
                i = i+1
        }
        
        # debugging stuff
#         if (length(matchings) == 0 || length(matchings) > 3)
#         {
#             cat(paste(c(tokens, "\n"), collapse=" "))
#             for (i in matchings)
#                 cat(sprintf("  %s\n", i))
#         }
        
        # remove duplicates
        matchings = unique(matchings)
        
        
        description = txt # at first I've assumed that final description will be different from the original but it's to difficult to implement
        
        # extract informations about at most 3 matched streets
        # TODO: refactor
        if (length(matchings) >= 3)
        {
            street3_ref_id = matchings[3]
            street3_prefix = db_streets_to_out[matchings[3],1]
            street3_name   = db_streets_to_out[matchings[3],2]
            street3_number = if (length(tokens)>=matchings_numpos[[3]][2] && 
                                     suppressWarnings(!is.na(as.numeric(tokens[matchings_numpos[[3]][2]]))) &&
                                     as.numeric(tokens[matchings_numpos[[3]][2]]) <= MAX_STREET_NUMBER
                                 ) 
                                tokens[matchings_numpos[[3]][2]]
                             else ""
        }
        if (length(matchings) >= 2)
        {
            street2_ref_id = matchings[2]
            street2_prefix = db_streets_to_out[matchings[2],1]
            street2_name   = db_streets_to_out[matchings[2],2]
            street2_number = if (length(tokens)>=matchings_numpos[[2]][2] && 
                                     suppressWarnings(!is.na(as.numeric(tokens[matchings_numpos[[2]][2]]))) &&
                                     (length(matchings)==2 || (matchings_numpos[[2]][2]!=matchings_numpos[[3]][1])) &&
                                     as.numeric(tokens[matchings_numpos[[2]][2]]) <= MAX_STREET_NUMBER
                                ) 
                                    tokens[matchings_numpos[[2]][2]]
                                else ""
        }
        if (length(matchings) >= 1)
        {
            street1_ref_id = matchings[1]
            street1_prefix = db_streets_to_out[matchings[1],1]
            street1_name   = db_streets_to_out[matchings[1],2]
            street1_number = if (length(tokens)>=matchings_numpos[[1]][2] && 
                                     suppressWarnings(!is.na(as.numeric(tokens[matchings_numpos[[1]][2]]))) &&
                                     (length(matchings)==1 || (matchings_numpos[[1]][2]!=matchings_numpos[[2]][1])) &&
                                     as.numeric(tokens[matchings_numpos[[1]][2]]) <= MAX_STREET_NUMBER
            ) 
                tokens[matchings_numpos[[1]][2]]
            else ""
        }
    }
    
    ret = data.frame(description    = description,
                     street1_ref_id = street1_ref_id,
                     street1_prefix = street1_prefix,
                     street1_name   = street1_name,
                     street1_number = street1_number,
                     street2_ref_id = street2_ref_id,
                     street2_prefix = street2_prefix,
                     street2_name   = street2_name,
                     street2_number = street2_number,
                     street3_ref_id = street3_ref_id,
                     street3_prefix = street3_prefix,
                     street3_name   = street3_name,
                     street3_number = street3_number)
    
    return(ret)
}

#________________________________________________

#loading input data and building streets list takes some time, so in one R session it's better to do it once;
#to reload data just type "rm(data_vars)"
data_vars = if (exists("data_vars")) data_vars else load_data()

db_input     = data_vars[[1]]
db_streets   = data_vars[[2]] 
dict_streets = data_vars[[3]]
db_streets_to_out = data_vars[[4]]

extracts_streets_and_places(DB_OUTPUT_SIZE)

dir.create(DB_OUTPUT_DIR_NAME, showWarnings=FALSE)
write.csv(db_output, file.path(DB_OUTPUT_DIR_NAME,DB_OUTPUT_FILE_NAME))