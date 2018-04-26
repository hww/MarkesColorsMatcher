#!/usr/bin/ruby
# ================================================================================
#
#         By: hww 
#  User page: https://github.com/hww
# Repository: https://github.com/hww/MarkesColorsMatcher
#
# ================================================================================
#
# Generate html file with table of matching Copic colors with Touch Twin colors
#
# ================================================================================
#
# Usage:
# bash> ./copic_to_touch.rb > copic_to_touch.html
#
# ================================================================================
#
# Note: 
#       * Use fro your own risk. I can't guaranty exact colors on paper.
#       * Can be used for other markers too
#
# ================================================================================
 
require "./copic"
require "./touch"
require "color_diff"

# ===========================================
# CONVERT COLORS
# ===========================================

def str_2_color(c)
	# return color in format [ r, g, b ]
	if c[0] == '#' then
		return ColorDiff::Color::RGB.new(c[1..2].to_i(16),  c[3..4].to_i(16),  c[5..6].to_i(16) ) 
	else
		puts "Unknown color: '#{c}'"
		return [0,0,0] # return non null
	end
end

# ===========================================
# PROCESS COPIC COLORS 
# ===========================================

def rgb_match?(c1, c2)
	# return value 0..1. It is level of matching of
	# colors in format [ r, g, b ]
	
	## ---------------------------------
	## LAB
	## ---------------------------------
	cc1 = c1[:rgb]
	cc2 = c2[:rgb]
	return ColorDiff.between(cc1,cc2)

end



# ===========================================
# PROCESS COPIC COLORS 
# ===========================================

@copic_colors_hash = {}

Copic.colors.each do |c|
	c[:rgb] = str_2_color(c[:color]);

	c[:ink] = false
	c[:touch_list] = []

	@copic_colors_hash[c[:id]] = c
end

Copic.inks.each do |c|
	@copic_colors_hash[c[:id]][:ink] = true
end

# ===========================================
# PROCESS TWIN COLORS 
# ===========================================

@twin_colors_hash = {}

Touch.colors.each do |t|
	
	t[:rgb] = str_2_color(t[:color]);

	t[:ink] = false
	t[:copic] = nil
	t[:match] = 0
	
	@twin_colors_hash[t[:id]] = t
end

Touch.inks.each do |t|
	@twin_colors_hash[t[:id]][:ink] = true
end

# ===========================================
# FIND COPICS TO TOUCHES WHICH WERE NOT ASSIGNED
# ===========================================

@max_diff = ColorDiff.between(ColorDiff::Color::RGB.new(0,0,0), ColorDiff::Color::RGB.new(255,255,255))

Touch.colors.each do |t|
	# for each 'touch' test check each 'copic'
	# and choose most closest one

	if (t[:copic].nil?)
		copic = nil
		level = 99999999999999999.0
		
		Copic.colors.each do |c|
			diff = ColorDiff.between(t[:rgb],c[:rgb]) / @max_diff 

			if (diff < level)
			then
				copic = c
				level = diff
			end
		end
		
		t[:copic] = copic
		t[:match] = level
		t[:perc] = 100.0 - level * 100.0
	end
end

# ===========================================
# ASSIGN TOUCHES TO COPICS
# ===========================================

Touch.colors.each do |t|
	# assign matched colors to the copics
	c = t[:copic]
	if (c)
	then
		c[:touch_list] << t;
	end
end

# ===========================================
# GENERATE HTML
# ===========================================

puts "<!DOCTYPE html>\n"
puts "<html>\n"
puts "<head>\n"
puts "<meta charset=\"utf-8\">\n"
puts "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
puts "<title>Matching Copic to Touch Twin Colors (Compact Table)</title>\n"
puts "</head>\n"
puts "<body>\n"

puts "<h2>Copic colors 2 Touch Twin colors (Compact)</h2>"
puts "<p>There are only colors available for Touch Twin!</p>"
puts "<span style=\"font-size:0.8em\">By: hww <i>(https://github.com/hww)</i></span><br>" 
puts "<span style=\"font-size:0.8em\">Source: <i>https://github.com/hww/MarkesColorsMatcher</i></span>" 

puts "<table>\n"
puts "<tr>"

Copic.families.each do |f|
	
	puts "<td valign=\"top\">"
	
	puts "<table>"
	puts "<tr>"
	puts "<td colspan=\"8\" style=\"background-color:#EEEEEE\"><b>#{f}<b></td>"
	puts "</tr>"
			
	Copic.colors.each do |c|
		
		id = c[:id]
		
		if (id.include?(f)) 
		then
		
			matches = c[:touch_list].size
			
			if (matches > 0)
			then 
			
				puts "<tr>"
				

				puts c[:ink] ? "<td>+</td>" : "<td></td>"
				puts "<td align=\"center\" style=\"background-color:#{c[:color]};color:#{c[:text]};font-size:0.8em;span:2px\">#{c[:id]}</td>"
			 
				add_row_beg = false
				add_row_end = true
				
				c[:touch_list].each do |t|
				
					if (add_row_beg)
					then
						puts "<tr>"

						puts "<td></td>"
						puts "<td></td>"

					end
					
					puts "<td style=\"font-size:0.8em\">#{(t[:perc]).to_i}%</td>"
					puts "<td align=\"center\" style=\"background-color:#{t[:color]};color:#{t[:text]};font-size:0.8em;span:2px\">#{t[:id]}</td>"
					puts t[:ink] ? "<td>+</td>" : "<td></td>"

					puts "</tr>"
					
					add_row_beg = true
					add_row_end = false;
				end
					
				if (add_row_end)
				then
					puts "<td></td>"
					puts "<td></td>"
					puts "<td></td>"

					puts "</tr>"
				end
					
				puts " "
			end
		end
	
	end
	puts "</table>"
	puts "</td>"
	
end
puts "</tr>"
puts "</table>\n"
puts "</body>\n"
