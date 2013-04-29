# -*- coding: utf-8 -*-
#
# Purpose:
# Extend the date parsing capabilities of Ruby to work with dates with international month names.
#
# Usage:
#
# Date.parse_international(date_string)
# DateTime.parse_international(date_string)
# date_string.to_international_date
#
# Notes:
# 1) This routine works by substituting your local month names (as defined by Date::MONTHNAMES) for the
#    international names when they occur in the date_string.
# 2) As distributed, this code works for French, German, Italian, and Spanish.  You must add the month 
#    names for any additional languages you wish to handle.
#

class Date
  def self.parse_international(string)
    parse(month_to_english(string))
  end

  private
  
  def self.make_hash(names)
    names.inject({}) {|result, name| result[name] = MONTHNAMES[result.count+1] ; result }      
  end

  MONTH_TRANSLATIONS = {}    
  MONTH_TRANSLATIONS.merge! make_hash(%w/janvier février mars avril mai juin juillet août septembre octobre novembre décembre/) # French
  MONTH_TRANSLATIONS.merge! make_hash(%w/Januar	Februar	März	April	Mai	Juni	Juli	August	September	Oktober	November	Dezember/)  # German
  MONTH_TRANSLATIONS.merge! make_hash(%w/gennaio	febbraio	marzo	aprile	maggio	giugno	luglio	agosto	settembre	ottobre	novembre	dicembre/)  # Italian
  MONTH_TRANSLATIONS.merge! make_hash(%w/enero	febrero	marzo	abril	mayo	junio	julio	agosto	septiembre	octubre	noviembre	diciembre/) # Spanish

  def self.month_to_english(string)
    month_from = string[/[^\s\d,]+/i]      # Search for a month name
    if month_from
      month_to = MONTH_TRANSLATIONS[month_from.downcase]      # Look up the translation
      return string.sub(month_from, month_to.to_s) if month_to
    end
    return string
  end
end

class DateTime
  def self.parse_international(string)
    parse(Date::month_to_english(string))
  end
end

class String
  def to_international_date
    Date::month_to_english(self).to_date
  end
end