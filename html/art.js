/* Item artwork (64x64 SVG). Used in the menu, on the wheel, and to render the
   ox_inventory item images in install/images. */
(function () {
    function gift(paper, ribbon, extra) {
        return `<g class="box"><rect x="10" y="28" width="44" height="30" rx="3" fill="${paper}"/><rect x="28" y="28" width="8" height="30" fill="${ribbon}"/>
        <rect x="10" y="40" width="44" height="6" fill="${ribbon}" opacity=".85"/>${extra || ''}</g>
        <g class="lid"><rect x="7" y="20" width="50" height="11" rx="3" fill="${paper}" stroke="rgba(0,0,0,.18)"/><rect x="28" y="20" width="8" height="11" fill="${ribbon}"/>
        <path d="M32 20c-8-12-20-6-12 0zM32 20c8-12 20-6 12 0z" fill="${ribbon}" stroke="rgba(0,0,0,.25)" stroke-width="1"/><circle cx="32" cy="19" r="3" fill="${ribbon}"/></g>`;
    }

    window.ART = {
        candy_cane: `<path d="M40 58V24a10 10 0 0 0-20 0v3" fill="none" stroke="#f6f1ea" stroke-width="9" stroke-linecap="round"/><path d="M40 58V24a10 10 0 0 0-20 0v3" fill="none" stroke="#d6283b" stroke-width="9" stroke-dasharray="4 6"/>`,

        hot_chocolate: `<path d="M24 10c-3 4 3 6 0 10M32 8c-3 4 3 6 0 10M40 10c-3 4 3 6 0 10" stroke="#dfe7e3" stroke-width="2" fill="none" stroke-linecap="round" opacity=".8"/>
            <path d="M44 32h4a7 7 0 0 1 0 14h-4" fill="none" stroke="#c8303f" stroke-width="4"/><path d="M14 24h32v24a8 8 0 0 1-8 8H22a8 8 0 0 1-8-8z" fill="#c8303f"/>
            <ellipse cx="30" cy="24" rx="16" ry="4" fill="#6b3a1f"/><rect x="21" y="20" width="7" height="6" rx="2" fill="#fff"/><rect x="30" y="19" width="7" height="6" rx="2" fill="#f3efe6" transform="rotate(12 33 22)"/>
            <path d="M18 36h24" stroke="#f3efe6" stroke-width="3" stroke-dasharray="3 3"/>`,

        gingerbread_man: `<g fill="#b8692f"><circle cx="32" cy="15" r="9"/><path d="M22 26h20l9 7-3 4-6-3v8l6 13-5 3-9-11-9 11-5-3 6-13v-8l-6 3-3-4z"/></g>
            <g fill="#fff"><circle cx="29" cy="13" r="1.4"/><circle cx="35" cy="13" r="1.4"/><circle cx="32" cy="30" r="1.6"/><circle cx="32" cy="36" r="1.6"/></g>
            <path d="M28 18q4 3 8 0" stroke="#fff" stroke-width="1.5" fill="none" stroke-linecap="round"/><circle cx="32" cy="26" r="2" fill="#c8303f"/>`,

        sugar_cookie: `<path d="M32 6l7 15 16 2-12 11 3 16-14-8-14 8 3-16L9 23l16-2z" fill="#e7c08a"/><path d="M32 12l5 11 11 1-8 8 2 11-10-6-10 6 2-11-8-8 11-1z" fill="#f5a7bf"/>
            <g fill="#fff"><circle cx="30" cy="24" r="1.2"/><circle cx="36" cy="30" r="1.2"/><circle cx="28" cy="33" r="1.2"/></g><circle cx="34" cy="22" r="1.2" fill="#6db3ff"/><circle cx="31" cy="38" r="1.2" fill="#7fd49b"/>`,

        eggnog: `<path d="M38 4l-6 16" stroke="#8a4b22" stroke-width="3" stroke-linecap="round"/><path d="M18 14h28l-3 40a4 4 0 0 1-4 4H25a4 4 0 0 1-4-4z" fill="#dff2ff" opacity=".35" stroke="#dff2ff" stroke-width="1.5"/>
            <path d="M20 22h24l-2.4 32a3 3 0 0 1-3 3H25.4a3 3 0 0 1-3-3z" fill="#f6e7b8"/><path d="M19 18q13 8 26 0v5H19z" fill="#fff"/>
            <g fill="#a0632f"><circle cx="28" cy="20" r="1"/><circle cx="34" cy="21" r="1"/><circle cx="31" cy="18" r=".8"/></g><path d="M24 26v26" stroke="#fff" stroke-width="2" opacity=".5" stroke-linecap="round"/>`,

        ornament_robin: `<rect x="28" y="6" width="8" height="7" rx="1" fill="#e9b955"/><circle cx="32" cy="6" r="3" fill="none" stroke="#e9b955" stroke-width="1.5"/><circle cx="32" cy="36" r="22" fill="#c8303f"/>
            <path d="M12 32q20 8 40 0" stroke="#e9b955" stroke-width="2" fill="none"/><ellipse cx="33" cy="42" rx="8" ry="6" fill="#6b4a33"/><circle cx="37" cy="37" r="4" fill="#6b4a33"/><path d="M33 44a5 4 0 0 0 7-3" fill="#f08a4b"/><path d="M41 37l3 1-3 1z" fill="#e9b955"/>
            <circle cx="24" cy="26" r="5" fill="#fff" opacity=".3"/>`,

        ornament_pinecone: `<path d="M32 8c-4 6-4 6 0 8" stroke="#2f7a5f" stroke-width="3" fill="none"/><path d="M26 10q-6-2-8 3q5 2 8-3zM38 10q6-2 8 3q-5 2-8-3z" fill="#2f7a5f"/>
            <g fill="#8a5a33" stroke="#5e3a1d" stroke-width="1.2"><path d="M32 16q-10 4-12 14q12 0 12-14z"/><path d="M32 16q10 4 12 14q-12 0-12-14z"/><path d="M32 26q-12 4-12 14q12-1 12-14z"/><path d="M32 26q12 4 12 14q-12-1-12-14z"/><path d="M32 38q-9 4-8 12q8-2 8-12z"/><path d="M32 38q9 4 8 12q-8-2-8-12z"/></g>
            <g fill="#fff" opacity=".85"><circle cx="24" cy="28" r="1.5"/><circle cx="40" cy="38" r="1.5"/><circle cx="28" cy="48" r="1.3"/><circle cx="36" cy="22" r="1.3"/></g>`,

        ornament_nutcracker: `<rect x="22" y="6" width="20" height="10" rx="2" fill="#1b1b2a"/><rect x="20" y="15" width="24" height="3" fill="#e9b955"/><rect x="23" y="18" width="18" height="12" rx="2" fill="#f2c9a6"/>
            <rect x="23" y="26" width="18" height="6" fill="#f3efe6"/><circle cx="28" cy="22" r="1.4" fill="#111"/><circle cx="36" cy="22" r="1.4" fill="#111"/><rect x="29" y="27" width="6" height="2" fill="#111"/>
            <rect x="21" y="32" width="22" height="14" rx="2" fill="#c8303f"/><path d="M32 32v14" stroke="#e9b955" stroke-width="2"/><rect x="21" y="44" width="22" height="3" fill="#1b1b2a"/>
            <rect x="23" y="47" width="7" height="11" fill="#1d4b3e"/><rect x="34" y="47" width="7" height="11" fill="#1d4b3e"/><rect x="22" y="56" width="20" height="3" rx="1" fill="#1b1b2a"/>`,

        ornament_snowglobe: `<path d="M14 52h36l-4 8H18z" fill="#8e1f2b"/><rect x="16" y="48" width="32" height="5" rx="2" fill="#e9b955"/><circle cx="32" cy="30" r="20" fill="#a9d7f0" opacity=".35" stroke="#dff2ff" stroke-width="2"/>
            <path d="M14 38q18 6 36 0v6a20 6 0 0 1-36 0z" fill="#f3efe6"/><path d="M32 18l8 14h-5l6 9H23l6-9h-5z" fill="#2f7a5f"/><rect x="30" y="41" width="4" height="4" fill="#6b3a1f"/>
            <g fill="#fff"><circle cx="20" cy="24" r="1.3"/><circle cx="42" cy="22" r="1.3"/><circle cx="26" cy="16" r="1"/><circle cx="44" cy="32" r="1"/></g><path d="M20 18a14 14 0 0 1 8-6" stroke="#fff" stroke-width="2" fill="none" opacity=".7" stroke-linecap="round"/>`,

        ornament_sleighbell: `<defs><radialGradient id="bellg" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#fff6d0" stop-opacity=".9"/><stop offset=".5" stop-color="#e9b955" stop-opacity="0"/><stop offset="1" stop-color="#7a4f0e" stop-opacity=".7"/></radialGradient></defs>
            <path d="M24 12a8 8 0 0 1 16 0" fill="none" stroke="#c8303f" stroke-width="5"/><circle cx="32" cy="36" r="22" fill="#e9b955"/><circle cx="32" cy="36" r="22" fill="url(#bellg)"/>
            <path d="M12 34h40" stroke="#9c6d1d" stroke-width="2"/><path d="M26 44h12" stroke="#3a2408" stroke-width="4" stroke-linecap="round"/><circle cx="32" cy="50" r="2.5" fill="#3a2408"/>`,

        ornament_star: `<circle cx="32" cy="32" r="28" fill="#ffc94a" opacity=".15"/><path d="M32 4l7.6 17.6L58 23l-14 12.6 4.2 19L32 44.8 15.8 54.6l4.2-19L6 23l18.4-1.4z" fill="#ffc94a" stroke="#fff3c4" stroke-width="2" stroke-linejoin="round"/>
            <path d="M32 14l4 10 10 1-8 7 3 10-9-6z" fill="#fff6d6" opacity=".6"/>`,

        money: `<rect x="8" y="22" width="46" height="26" rx="3" fill="#2e7d4f" transform="rotate(-8 31 35)"/><rect x="10" y="20" width="46" height="26" rx="3" fill="#3f9e63" stroke="#cfeedd" stroke-width="1.5"/>
            <circle cx="33" cy="33" r="8" fill="#cfeedd"/><text x="33" y="37.5" font-family="Georgia,serif" font-size="13" font-weight="700" fill="#2e7d4f" text-anchor="middle">$</text>
            <circle cx="16" cy="26" r="2" fill="#cfeedd"/><circle cx="50" cy="40" r="2" fill="#cfeedd"/>`,

        xmas_present: gift('#c8303f', '#2f7a5f'),
        xmas_present_silver: gift('#b9c6d0', '#3b6fb3', '<g fill="#fff" opacity=".6"><circle cx="16" cy="34" r="1.3"/><circle cx="48" cy="52" r="1.3"/><circle cx="20" cy="54" r="1"/></g>'),
        xmas_present_gold: gift('#e9b955', '#c8303f', '<path d="M12 30l40 26M12 46l20 12" stroke="#fff3c4" stroke-width="1" opacity=".6"/>'),
        xmas_present_northstar: gift('#1b2a5a', '#e9b955', '<path d="M18 34l1.5 3 3 .4-2.2 2 .6 3-2.9-1.6-2.9 1.6.6-3-2.2-2 3-.4zM46 48l1.2 2.4 2.4.3-1.8 1.6.5 2.4-2.3-1.3-2.3 1.3.5-2.4-1.8-1.6 2.4-.3z" fill="#ffe28a"/>'),
    };
})();
