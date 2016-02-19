library(xlsx)

#_______________________________________________

INTERVENTIONS_FILE = "gen/parsed-poznan-mp-interventions-2013-06-17-2013-10-09.csv"
CITIZENS_FILE      = "db/poznan-districts-citizens.csv"

TIME_REPORT_FILE   = "gen/time_report.png"
OUTPUT_XLSX_FILE   = "gen/stats-poznan-mp-interventions-2013-06-17-2013-10-09.xlsx"

#_______________________________________________

db_input    = read.csv(INTERVENTIONS_FILE)
db_citizens = read.csv(CITIZENS_FILE, row.names="district")


stats.districts = cbind(db_citizens,
                        data.frame(reports=as.vector(table(db_input$district)), #or summary(...,maxsum=Inf)
                                   row.names=rownames(db_citizens))
                       )

stats.districts = rbind(t(data.frame("all districts"=colSums(stats.districts), check.names=FALSE)),
                        stats.districts)

stats.districts = cbind(stats.districts,
                        data.frame("reports per citizen"=
                                       round(stats.districts$reports/stats.districts$citizens, 2),
                                   check.names=FALSE)
                       )

stats.categories = cbind(data.frame("all categories"=summary(db_input$district, maxsum=Inf),
                                    check.names=FALSE),
                         data.frame(aggregate(category ~ district, db_input, table)$category,
                                    row.names=levels(db_input$district),
                                    check.names=FALSE)
                        )
stats.categories = rbind(t(data.frame("all districts"=colSums(stats.categories), check.names=FALSE)),
                         stats.categories)

#________________________________________________________

time_freq = data.frame(freq=as.vector(table(db_input$time)), row.names=names(table(db_input$time)))

times = expand.grid(0:23,0:59)
times = times[order(times[,1]),]
times = paste(sprintf("%02d", as.numeric(times$Var1)), sprintf("%02d", as.numeric(times$Var2)), sep=":")
times = data.frame(freq=rep(0,length(times)), row.names=times)
times = data.frame(freq=merge(time_freq,times,by=0,all=TRUE)[,2], row.names=rownames(times))
times[is.na(times)] = 0

png(TIME_REPORT_FILE, width = 900, height = 500)

plot(times$freq, type="h", xaxt="n", xlab="time of report", ylab="frequency")
title("all districts")
hours_ids = seq(1,dim(times)[1],60)
axis(1, at=c(hours_ids, dim(times)[1]+1), labels=c(rownames(times)[hours_ids], "24:00"))

dev.off()

#________________________________________________________

wb = createWorkbook()

sh_districts = createSheet(wb=wb, sheetName="districts")
sh_catvsdist1 = createSheet(wb=wb, sheetName="categories (heat per category)")
sh_catvsdist2 = createSheet(wb=wb, sheetName="categories (heat per district)")
sh_timereport = createSheet(wb=wb, sheetName="time of reports")
addDataFrame(x=stats.districts,  sheet=sh_districts)
addDataFrame(x=stats.categories, sheet=sh_catvsdist1)
addDataFrame(x=stats.categories, sheet=sh_catvsdist2)
addPicture(TIME_REPORT_FILE, sh_timereport)
saveWorkbook(wb, OUTPUT_XLSX_FILE)

unlink(TIME_REPORT_FILE)
