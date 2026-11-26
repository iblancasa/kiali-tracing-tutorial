"""frontend: the only service reachable from outside the mesh. Serves the
page and the public API, and delegates everything else."""
import flask

from .common import call, create_app, upstream_error, work

app = create_app('frontend')

PAGE = """<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>Mesh Pizza</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
 body{font-family:system-ui,sans-serif;max-width:46rem;margin:2rem auto;padding:0 1rem;color:#222;background:#fffaf3}
 h1{margin-bottom:0}.sub{color:#777;margin-top:.2rem}
 .pizza{display:flex;justify-content:space-between;align-items:center;gap:1rem;padding:.8rem 1rem;margin:.6rem 0;background:#fff;border:1px solid #eadfce;border-radius:.6rem}
 .pizza small{color:#777;display:block}button{background:#c0392b;color:#fff;border:0;border-radius:.4rem;padding:.5rem .9rem;font-size:1rem;cursor:pointer}
 button:disabled{opacity:.5}#log{font-family:ui-monospace,monospace;font-size:.85rem;white-space:pre-wrap;background:#222;color:#eee;padding:.8rem;border-radius:.6rem;min-height:3rem}
 .old{text-decoration:line-through;color:#999;margin-right:.3rem}
</style></head><body>
<h1>Mesh Pizza</h1><p class="sub">Fifteen workloads to deliver one pizza.</p>
<div id="menu">Loading the menu...</div>
<h3>Orders</h3><div id="log">Nothing ordered yet.</div>
<script>
const log = (m) => { const l = document.getElementById('log'); l.textContent = m + '\\n' + l.textContent; };
async function order(id, b) {
  b.disabled = true; const t = performance.now();
  const r = await fetch('/api/orders', {method: 'POST', headers: {'content-type': 'application/json'}, body: JSON.stringify({pizza: id, qty: 1})});
  const j = await r.json(); const ms = Math.round(performance.now() - t);
  log(r.ok ? `order ${j.order} confirmed: ${id}, arrives in ${j.eta_minutes} min (${ms} ms)` : `order failed: HTTP ${r.status} ${j.error} (${ms} ms)`);
  b.disabled = false;
}
fetch('/api/menu').then(r => r.json()).then(j => {
  document.getElementById('menu').innerHTML = j.pizzas.map(p => `<div class="pizza"><div><b>${p.name}</b>
    <small>${p.reviews.map(r => (r.stars ? '★'.repeat(r.stars) + ' ' : '') + r.text).join(' · ')}</small></div>
    <div>${p.list_price !== p.price ? `<span class="old">${p.list_price.toFixed(2)}</span>` : ''}${p.price.toFixed(2)} €
    <button onclick="order('${p.id}', this)">Order</button></div></div>`).join('');
}).catch(e => { document.getElementById('menu').textContent = 'The menu is not available: ' + e; });
</script></body></html>
"""


@app.route('/')
def index():
    return PAGE


@app.route('/api/menu')
def menu():
    work(2, 8)
    response = call('GET', 'menu', '/menu')
    if response.status_code != 200:
        return upstream_error('menu', response)
    return flask.jsonify(response.json())


@app.route('/api/orders', methods=['POST'])
def orders():
    work(2, 8)
    order = flask.request.get_json(silent=True) or {}
    response = call('POST', 'orders', '/orders', json={
        'pizza': order.get('pizza', 'margherita'),
        'qty': int(order.get('qty', 1)),
        'address': order.get('address', 'Calle Mayor 1'),
    })
    if response.status_code != 200:
        return upstream_error('orders', response)
    return flask.jsonify(response.json())
