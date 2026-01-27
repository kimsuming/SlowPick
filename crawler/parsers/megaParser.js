// src/parsers/megaParser.js
const cheerio = require('cheerio');

function parseMega(htmlContent) {
  const $ = cheerio.load(htmlContent);
  const menus = [];

  $('#menu_list li').each((i, el) => {
    const nameNode = $(el).find('.cont_text_title b').first();
    if (nameNode.length === 0) return;
    
    const name = nameNode.text().trim();
    const imgUrl = $(el).find('.cont_gallery_list_img img').attr('src');
    const $modal = $(el).find('.inner_modal');

    // SlowPick 표준 스키마에 맞춘 nutrition 구조
    const nutrition = {
      calories_kcal: 0,
      sugar_g: 0,
      protein_g: 0,
      sodium_mg: 0,
      saturated_fat_g: 0,
      caffeine_mg: 0,
      size_standard: "정보 없음" 
    };

    $modal.find('.cont_text').each((j, textDiv) => {
      $(textDiv).find('.cont_text_inner').each((k, innerDiv) => {
        const text = $(innerDiv).text().trim();
        if (text.includes('1회 제공량')) {
          const calMatch = text.match(/[\d\.]+/); 
          nutrition.calories_kcal = calMatch ? parseFloat(calMatch[0]) : 0;
        } else if (text.match(/\d+ml|\d+oz/i)) {
          nutrition.size_standard = text;
        }
      });
    });

    $modal.find('.cont_list_small2 ul li').each((j, li) => {
      const text = $(li).text().trim();
      const numMatch = text.match(/[\d\.]+/);
      const val = numMatch ? parseFloat(numMatch[0]) : 0;

      if (text.includes('당류')) nutrition.sugar_g = val;
      else if (text.includes('단백질')) nutrition.protein_g = val;
      else if (text.includes('나트륨')) nutrition.sodium_mg = val;
      else if (text.includes('포화지방')) nutrition.saturated_fat_g = val;
      else if (text.includes('카페인')) nutrition.caffeine_mg = val;
    });

    let allergyInfo = [];
    const allergyText = $modal.find('.cont_text_info').text();
    if (allergyText.includes('알레르기 성분')) {
      let rawAllergy = allergyText.split('알레르기 성분 :')[1] || "";
      rawAllergy = rawAllergy.replace(/고카페인\s*함유/g, "");
      allergyInfo = rawAllergy.split(',')
        .map(s => s.trim())
        .filter(s => s && s !== "");
    }

    menus.push({
      brand_name: "메가MGC커피",
      category: "음료",
      menu_name: name,
      menu_image_url: imgUrl || "",
      is_active: true,
      menu_type: "regular",
      nutrition: nutrition,
      allergy_info: allergyInfo,
      description: $(el).find('.cont_gallery_list_label').text().trim() || ""
    });
  });

  return menus;
}

module.exports = { parseMega };