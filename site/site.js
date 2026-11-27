// SPDX-License-Identifier: AGPL-3.0-or-later
const comparison = document.querySelector('#comparison');
const slider = document.querySelector('#reveal');
const processed = document.querySelector('#processed');
const active = document.querySelector('#active-effect');
const grid = document.querySelector('#effect-options');

slider.addEventListener('input', () => {
  comparison.style.setProperty('--reveal', `${slider.value}%`);
  slider.setAttribute('aria-valuetext', `${slider.value}% effect visible`);
});

grid.addEventListener('click', event => {
  const button = event.target.closest('button[data-effect]');
  if (!button) return;
  const name = button.querySelector('strong').textContent;
  processed.src = button.querySelector('img').src;
  processed.alt = `${name} applied to the portrait`;
  active.textContent = name.toUpperCase();
  grid.querySelector('[aria-pressed="true"]').setAttribute('aria-pressed', 'false');
  button.setAttribute('aria-pressed', 'true');
});

document.querySelector('#copy').addEventListener('click', async () => {
  const status = document.querySelector('#copy-status');
  const commands = document.querySelector('#commands');
  try {
    await navigator.clipboard.writeText(commands.textContent);
    status.textContent = 'Commands copied.';
  } catch {
    const range = document.createRange();
    range.selectNodeContents(commands);
    window.getSelection().removeAllRanges();
    window.getSelection().addRange(range);
    status.textContent = 'Commands selected. Press Command-C to copy.';
  }
});
