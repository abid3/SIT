###############################################################################
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################
# Collection of routines to work with data
# Copyright (C) 2011  Michael Kapler
#
# For more information please visit my blog at www.SystematicInvestor.wordpress.com
# or drop me a line at TheSystematicInvestor at gmail
###############################################################################

###############################################################################
# extract.table.from.webpage
###############################################################################
extract.table.from.webpage <- function
(
	txt, 		# source text of webpage
	marker,		# key-phrase(s) located in the table to extract
	hasHeader=T	# flag if table has a header
)
{
	tryCatch({		
		# find location of data
		marker = spl(marker)
		pos1=1
		
		for(i in 1:len(marker)) {
			pos1 = regexpr(marker[i], substr(txt, pos1, nchar(txt))) + pos1
		}
		
		# find start/end of table
		pos0 = tail(gregexpr('<table', substr(txt, 1, pos1))[[1]], 1)
		pos2 = head(gregexpr('</table', substr(txt, pos1, nchar(txt)))[[1]], 1)
		temp =  substr(txt, pos0, pos1 + pos2 - 2)
	
		# remove all formating	
		temp = gsub(pattern = '<br>', replacement = '', temp, perl = TRUE) 
		
		temp = gsub(pattern = '</tr>', replacement = ';row;', temp, perl = TRUE) 
		temp = gsub(pattern = '</td>', replacement = ';col;', temp, perl = TRUE) 
		temp = gsub(pattern = '</th>', replacement = ';col;', temp, perl = TRUE) 
						
		temp = gsub(pattern = '<.*?>', replacement = '', temp, perl = TRUE) 
		
		temp = gsub(pattern = '\r', replacement = '', temp, perl = TRUE) 
		temp = gsub(pattern = '\n', replacement = '', temp, perl = TRUE) 
		temp = gsub(pattern = '\t', replacement = '', temp, perl = TRUE) 
		temp = gsub(pattern = '&nbsp;', replacement = '', temp, perl = TRUE) 
		temp = gsub(pattern = '&amp;', replacement = '', temp, perl = TRUE) 
		temp = gsub(pattern = '&raquo;', replacement = '', temp, perl = TRUE) 		
				
		# parse into matrix	
		temp = lapply( strsplit(temp, ';row;'), strsplit, ';col;')	
		n = max( sapply(temp[[1]], function(x) len(x)) )
		temp = t( sapply(temp[[1]], function(x) x[1:n]) )
		
		if(hasHeader) {
			colnames(temp) = temp[1, ]
			temp = temp[-1, ]
		}

	}, error = function(ex) {
		temp <<- txt
	}, finally = {
		return(temp)
	})
}
 	
###############################################################################
# Test for extract.table.from.webpage function
###############################################################################
extract.table.from.webpage.test <- function()
{
	load.packages('quantmod')

	Symbol = 'IBM'	
	
	# download Key Statistics from yahoo	
	url = paste('http://finance.yahoo.com/q/ks?s=', Symbol, sep = '')
	txt = join(readLines(url))

	# extract Valuation Measures table from this page
	temp = extract.table.from.webpage(txt, 'Market Cap', hasHeader = F)
		temp = rbind(c('', Symbol), temp)	# add header row

		
	# download IBM price history from Yahoo
	data = getSymbols(Symbol, from = '1980-01-01', auto.assign = FALSE)
		
	# prepare IBM data for 2010:2011 and compute 50 days moving average
	y = data['2010::2011']
	sma50 = SMA(Cl(y), 50)
	
	png(filename = 'plot1.png', width = 500, height = 500, units = 'px', pointsize = 12, bg = 'white')
	
	# plote candles and volume and table	
	layout(c(1,1,2,3,3))		
	
	plota(y, type = 'candle', main = Symbol, plotX = F)
		plota.lines(sma50, col='blue')
		plota.legend(c(Symbol,'SMA 50'), 'green,blue', list(y,sma50))
		
	y = plota.scale.volume(y)
	plota(y, type = 'volume')		
		
	plot.table(temp)	
	
	dev.off()		
}