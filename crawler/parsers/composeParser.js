// src/parsers/composeParser.js
const cheerio = require('cheerio');

function parseCompose(htmlContent) {
  const $ = cheerio.load(htmlContent);
  const menus = [];

  $('div.itemBox').each((i, el) => {
    const name = $(el).find('.undertitle').text().trim();
    if (!name) return;

    let imgUrl = $(el).find('.rthumbnailimg').attr('src');
    if (imgUrl && !imgUrl.startsWith('http')) {
      imgUrl = `https://composecoffee.com${imgUrl}`;
    }

    const nutrition = {
      calories_kcal: 0, 
      sugar_g: 0, 
      protein_g: 0,
      sodium_mg: 0, 
      saturated_fat_g: 0, 
      caffeine_mg: 0,
      size_standard: "정보 없음"
    };

    $(el).find('.caption .info li.extra').each((j, li) => {
      // 2. 특수문자 제거 및 텍스트 정리
      const text = $(li).text().replace('⚬', '').trim(); 
      if (!text) return;

      const extractNumber = (str) => {
        const valuePart = str.split(':')[1] || str;
        const match = valuePart.match(/[0-9]+(\.[0-9]+)?/);
        return match ? parseFloat(match[0]) : 0;
      };

      if (text.includes('용량')) {
        const sizeValue = text.split(':')[1]?.trim();
        if (sizeValue) nutrition.size_standard = sizeValue;
      } 
      else if (text.includes('열량')) nutrition.calories_kcal = extractNumber(text);
      else if (text.includes('당류')) nutrition.sugar_g = extractNumber(text);
      else if (text.includes('단백질')) nutrition.protein_g = extractNumber(text);
      else if (text.includes('나트륨')) nutrition.sodium_mg = extractNumber(text);
      else if (text.includes('포화지방')) nutrition.saturated_fat_g = extractNumber(text);
      else if (text.includes('카페인')) nutrition.caffeine_mg = extractNumber(text);
    });

    menus.push({
      brand_name: "컴포즈커피",
      category: "음료",
      menu_name: name,
      menu_image_url: imgUrl || "",
      is_active: true,
      menu_type: "regular",
      nutrition: nutrition,
      allergy_info: [],
      description: "" 
    });
  });

  return menus;
}

module.exports = { parseCompose };