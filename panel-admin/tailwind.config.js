/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        primary:    '#DEBA3B',
        'primary-dark': '#B8962A',
        bg:         '#121212',
        surface:    '#1E1E1E',
        'surface-alt': '#2A2A2A',
        border:     '#333333',
        hint:       '#888888',
        success:    '#4CAF50',
        error:      '#CF6679',
        warning:    '#FF9800',
      }
    }
  },
  plugins: []
}
