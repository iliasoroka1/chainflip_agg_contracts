const defaultTheme = require("tailwindcss/defaultTheme");
const colors = require("tailwindcss/colors");
const {
  default: flattenColorPalette,
} = require("tailwindcss/lib/util/flattenColorPalette");
const svgToDataUri = require("mini-svg-data-uri");


/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx}',
    './components/**/*.{js,ts,jsx,tsx}',
    './app/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        gray0: '#17171A',
        gray1: '#191B1F',
        gray2: '#101216',
        gray3: '#010510',
        gray4: '#1E1F25',
        gray300: '#B3B4B7',
        blueMax: '#5FBBE5',
        gray400: '#808287',
        borderUnselected: '#2A2D36',
        borderSelected: '#4D5058',
        softgreen: '#BFE3B4',
        smoothblue: '#0BBBFA',
        smoothgreen: '#B5B5B5',
        smoothyellow: '#F2C94C',
        smoothred: '#FF6961',
        darkslate: '#0A0D16',
        neompurple: '#B5B5B5',
        stYellow: '#F5BCD0',
        stYellowWhite: '#B5B5B5',
        base: '#1C1E26',
        secGrey: '#B5B5B5',
        pink: '#F5BCD0',
        pinkw: '#191B1F',
        button: '#E8DABC',
        b: '#141A24', // token input background
        bw: '#141A24', // token input background
        button: '#F5BCD0',
        buttonw: '#F5BCD0',
        tokyonight: '#1A237E',
        darkShadow: '0 2px 15px #F5BCD0',
        lightShadow: '0 5px 15px #F5BCD0',
        tokyonight2: '#1E40AF',

        textDark: '#F5BCD0',
        textLight: '#F5BCD0',

        buttonDark: '#F5BCD0',
        buttonLight: '#F5BCD0',

        bgDark: '#1C1E26',
        bgLight: '#F5BCD0',

        secondaryDark: '#1C1E26',
        secondaryLight: '#B5B5B5',

        borderDark: '#1C1E26',
        borderLight: '#F5BCD0',
      },
      background: '#000',
      borderRadius: {
        20: '20px',
      },
      width: {
        100: '460px',
      },
      maxWidth: {
        '80%': '80%',
      },
      fontSize: {
        xxs: '10px',
        '3.5xl': '32px',
      },
      screens: {
        xl: { max: '1200px' },
        lg: { min: '767px', max: '1024px' },
        md: { min: '479px', max: '768px' },
        sm: { max: '480px' },
      },
      fontFamily: {
        AeonikPro: ['AeonikPro', 'Helvetica', 'Arial', 'sans-serif'],
      },
      blur: {
        '4xl': '164px',
      },
    },
  },
  plugins: [
    addVariablesForColors,
    function ({ matchUtilities, theme }) {
      matchUtilities(
        {
          "bg-grid": (value) => ({
            backgroundImage: `url("${svgToDataUri(
              `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32" fill="none" stroke="${value}"><path d="M0 .5H31.5V32"/></svg>`
            )}")`,
          }),
          "bg-grid-small": (value) => ({
            backgroundImage: `url("${svgToDataUri(
              `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="8" height="8" fill="none" stroke="${value}"><path d="M0 .5H31.5V32"/></svg>`
            )}")`,
          }),
          "bg-dot": (value) => ({
            backgroundImage: `url("${svgToDataUri(
              `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="16" height="16" fill="none"><circle fill="${value}" id="pattern-circle" cx="10" cy="10" r="1.6257413380501518"></circle></svg>`
            )}")`,
          }),
        },
        { values: flattenColorPalette(theme("backgroundColor")), type: "color" }
      );
    },
  ],

}
function addVariablesForColors({ addBase, theme }) {
  let allColors = flattenColorPalette(theme("colors"));
  let newVars = Object.fromEntries(
    Object.entries(allColors).map(([key, val]) => [`--${key}`, val])
  );
 
  addBase({
    ":root": newVars,
  });
}
