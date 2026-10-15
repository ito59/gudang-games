import defaultTheme from 'tailwindcss/defaultTheme';
import forms from '@tailwindcss/forms';

/** @type {import('tailwindcss').Config} */
export default {
    content: [
        './vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php',
        './storage/framework/views/*.php',
        './resources/views/**/*.blade.php',
        './resources/js/**/*.vue',
    ],

    theme: {
        extend: {
            // The Flutter app's cream-and-gold palette (lib/theme/app_colors.dart).
            colors: {
                cream: '#F7F1E5',
                ink: {
                    DEFAULT: '#221C15',
                    soft: '#6E6254',
                    muted: '#857868',
                },
                line: {
                    DEFAULT: '#DCCDB0',
                    soft: '#EDE3D0',
                },
                fill: {
                    DEFAULT: '#F4ECDC',
                    alt: '#F5EBD6',
                },
                brand: {
                    DEFAULT: '#B3191E',
                    dark: '#8F1217',
                },
                gold: {
                    light: '#F3E4BF',
                    DEFAULT: '#D9BC80',
                    deep: '#BF9A55',
                    on: '#2B2116',
                    ink: '#A9823D',
                    // goldInk darkened enough to read as small link text on white.
                    link: '#86662B',
                },
                online: {
                    DEFAULT: '#2BA55A',
                    ink: '#1E7D43',
                },
            },
            fontFamily: {
                sans: ['"Hanken Grotesk"', ...defaultTheme.fontFamily.sans],
                display: ['Sora', ...defaultTheme.fontFamily.sans],
            },
            borderRadius: {
                card: '18px',
            },
            boxShadow: {
                card: '0 6px 18px rgba(90, 66, 32, 0.08)',
                lift: '0 10px 24px rgba(90, 66, 32, 0.14)',
            },
        },
    },

    plugins: [forms],
};
