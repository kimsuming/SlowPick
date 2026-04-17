// src/parsers/megaParser.js

console.log('[Angel] line-based parser loaded');

const cheerio = require('cheerio');

function normalizeText(value = '') {
  return String(value).replace(/\s+/g, ' ').trim();
}

function parseNumber(text) {
  if (!text) return null;
  const match = String(text).match(/[\d.]+/);
  if (!match) return null;

  const num = parseFloat(match[0]);
  return Number.isNaN(num) ? null : num;
}

function parseMega(htmlContent) {
  const $ = cheerio.load(htmlContent);
  const menus = [];

  $('#menu_list li').each((i, el) => {
    const nameNode = $(el).find('.cont_text_title b').first();
    if (nameNode.length === 0) return;

    const name = normalizeText(nameNode.text());
    const imgUrl = normalizeText($(el).find('.cont_gallery_list_img img').attr('src') || '');
    const $modal = $(el).find('.inner_modal');

    let calories = null;
    let sugar = null;
    let protein = null;
    let sodium = null;
    let saturatedFat = null;
    let caffeine = null;
    let sizeStandard = null;

    $modal.find('.cont_text').each((j, textDiv) => {
      $(textDiv).find('.cont_text_inner').each((k, innerDiv) => {
        const text = normalizeText($(innerDiv).text());

        if (!text) return;

        if (text.includes('1회 제공량')) {
          calories = parseNumber(text);
        } else if (/\d+\s*(ml|oz)/i.test(text)) {
          sizeStandard = text;
        }
      });
    });

    $modal.find('.cont_list_small2 ul li').each((j, li) => {
      const text = normalizeText($(li).text());
      const val = parseNumber(text);

      if (text.includes('당류')) sugar = val;
      else if (text.includes('단백질')) protein = val;
      else if (text.includes('나트륨')) sodium = val;
      else if (text.includes('포화지방')) saturatedFat = val;
      else if (text.includes('카페인')) caffeine = val;
    });

    let allergyInfo = [];
    const allergyText = normalizeText($modal.find('.cont_text_info').text());

    if (allergyText.includes('알레르기 성분')) {
      let rawAllergy = allergyText.split('알레르기 성분 :')[1] || '';
      rawAllergy = rawAllergy.replace(/고카페인\s*함유/g, '');
      allergyInfo = rawAllergy
        .split(',')
        .map(s => normalizeText(s))
        .filter(Boolean);
    }

    const nutritionJson = {
      calories,
      sugar,
      protein,
      sodium,
      saturated_fat: saturatedFat,
      caffeine,
      size_standard: sizeStandard,
    };

    menus.push({
      brand_name: '메가MGC커피',
      category: '음료',
      menu_name: name,
      description: normalizeText($(el).find('.cont_text_box > .cont_text.cont_text_info .text.text2').text()) || null,
      size_standard: sizeStandard,
      image_url: imgUrl || null,
      is_active: true,
      menu_type: 'regular',

      calories,
      sugar,
      protein,
      caffeine,
      saturated_fat: saturatedFat,
      sodium,

      nutrition_json: nutritionJson,
      allergy_info: allergyInfo,
    });
  });

  return menus;
}

module.exports = { parseMega };