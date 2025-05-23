##' Update the pirana-style comments in top of a Nonmem control stream
##'
##' @param file.mod The control stream to edit
##' @param description The desription to put in the preamble comments
##' @param based.on A control stream that the model was based on (will be a comment in preamble).
##' @param author Name of author to credit in preamble
##' @param write.file Write to file? If not, resulting control stream will be returned user as lines, and nothing else done.
##' @return lines (charachter) for new control stream
##' @keywords internal

## should use getLines so user can specify either file.mod or lines 
NMwritePreamble <- function(file.mod,lines,description=NULL,based.on=NULL,author=NULL,write.file=TRUE){

    line <- NULL
    has.field <- NULL
    line.field <- NULL
    has.name <- NULL
    text <- NULL
    full.name <- NULL
    name <- NULL
    contents <- NULL
    text.new <- NULL
    contents.updated <- NULL
    include <- NULL

    
    
    lines <- getLines(file=file.mod,lines=lines)
    ## lines <- readLines(file.mod)

    all.idx <- NMreadSection(lines=lines,return="idx")
    code.start <- min(do.call(c,all.idx))
    if( is.na(code.start) || code.start==1 ){
        return(lines)
    }

    
    pretext <- lines[1:(code.start-1)]
    dt.pretext <- data.table(text=pretext)[,line:=.I]
    ## what lines have fields
    dt.pretext[,has.field:=grepl(" *;+ *[a-zA-Z]*[0-9]+\\. *.*",pretext)]
    dt.pretext[has.field==TRUE,line.field:=line]
    dt.pretext[,line.field:=nafill(line.field,type="locf")]
    
    ## does the field have a name?
    dt.pretext[,has.name:=has.field&grepl(" *;+ *[a-zA-Z]*[0-9]+\\. *.*:.*",text)]
    dt.pretext[has.name==TRUE,full.name:=sub("(.*: ).*","\\1",text)]
    ## names of fields (if any)
    dt.pretext[has.name==TRUE,name:=sub(" *;+ *[a-zA-Z]*[0-9]+\\. *([^\\:]*):.*","\\1",text)]
    ## not needed to extract contents 
    dt.pretext[,contents:=NA_character_]
    ## modify contents
    if(!is.null(based.on)){
        dt.pretext[name=="Based on",
                   contents:=sub("^ *[a-zA-Z]*","",fnExtension(basename(based.on),""))]
    }
    if(!is.null(description)){
        dt.pretext[name=="Description",
                   contents:=description]
    }
    if(!is.null(author)){
        dt.pretext[name=="Author",
                   contents:=author]
    }


    ## put back together
    dt.pretext[,text.new:=NA_character_]
    
    dt.pretext[!is.na(contents),text.new:=paste(full.name,contents)]
    dt.pretext[,contents.updated:=NA_integer_]
    dt.pretext[!is.na(contents),contents.updated:=1]
    dt.pretext[,contents.updated:=nafill(contents.updated,type="locf"),by=line.field]
    ## todo: skip lines that are not fields after updated lines
    ## line counter
    ## line.field is the line that holds the field
    ## carry forward if field was edited.
    ## then don't include lines that belongs to fields that were edited.

    dt.pretext[,include:=is.na(line.field) | line.field==line | !contents.updated]
    
    dt.pretext[is.na(text.new),text.new:=text]
    dt.pretext

    ## replace preamble in control stream
    lines <- c(dt.pretext[include==TRUE,text.new],lines[code.start:length(lines)])

    ## write to file
    if(write.file){
        writeTextFile(lines=lines,file=file.mod)
        return( invisible(lines))
    }

    return( lines)


}
