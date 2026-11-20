import type { Fulfillment } from '@spree/sdk';
import { marketplace, type PickupPoint } from '@/lib/spree';
import { selectPickupPoint } from '@/app/actions';

type FulfillmentWithPickup = Fulfillment & { pickup_point?: PickupPoint | null; pickup_point_required?: boolean };

/** Lists pickup points near the delivery address (or a searched suburb/postal code) for the chosen partner */
export async function PickupPointPicker({
  fulfillment,
  postalCode,
  search,
}: {
  fulfillment: FulfillmentWithPickup;
  postalCode?: string | null;
  search?: string;
}) {
  const rate = fulfillment.delivery_rates.find((r) => r.selected);
  if (!rate || !fulfillment.pickup_point_required) return null;
  const partner = (rate.delivery_method as unknown as { partner?: { name: string } }).partner?.name ?? 'pickup';
  const query = search?.trim();
  const points = await marketplace.pickupPoints
    .list(rate.delivery_method.id, { postal_code: /^\d{4}$/.test(query ?? '') ? query : postalCode ?? undefined, q: query && !/^\d{4}$/.test(query) ? query : undefined, limit: 5 })
    .then((r) => r.data)
    .catch(() => [] as PickupPoint[]);
  const chosen = fulfillment.pickup_point;

  return (
    <div className="mt-4 rounded-2xl border-2 border-dashed border-ink bg-cream p-4">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <p className="font-display text-lg font-extrabold">📍 Choose your {partner} point</p>
        <form className="flex gap-2" action="/checkout">
          <input name="pickup_q" defaultValue={query} placeholder="Suburb or postal code" className="field py-2 text-sm" />
          <button className="btn btn-light px-4 py-2 text-sm">Search</button>
        </form>
      </div>
      {points.length === 0 ? (
        <p className="mt-3 text-sm font-bold text-flame">No {partner} points found nearby — try another suburb or postal code.</p>
      ) : (
        <ul className="mt-3 space-y-2">
          {points.map((p) => {
            const isChosen = chosen?.external_id === p.external_id;
            return (
              <li key={p.external_id}>
                <form action={selectPickupPoint}>
                  <input type="hidden" name="fulfillment_id" value={fulfillment.id} />
                  <input type="hidden" name="pickup_point_id" value={p.external_id} />
                  <button
                    className={`flex w-full items-start gap-3 rounded-xl border-2 border-ink p-3 text-left text-sm transition hover:bg-lime ${isChosen ? 'bg-lime' : 'bg-white'}`}
                    aria-pressed={isChosen}
                  >
                    <span className={`mt-0.5 grid h-5 w-5 shrink-0 place-items-center rounded-full border-2 border-ink ${isChosen ? 'bg-ink text-white' : ''}`}>{isChosen ? '✓' : ''}</span>
                    <span className="flex-1">
                      <span className="block font-bold">{p.name}</span>
                      <span className="block text-ink/70">{[p.address.street, p.address.suburb, p.address.city, p.address.postal_code].filter(Boolean).join(', ')}</span>
                      {p.opening_hours && <span className="block text-xs text-ink/60">🕒 {p.opening_hours}</span>}
                    </span>
                  </button>
                </form>
              </li>
            );
          })}
        </ul>
      )}
      {points.some((p) => p.metadata?.sample) && (
        <p className="mt-3 text-xs text-ink/60">Demo data: these are sample points until the live partner directory is connected.</p>
      )}
    </div>
  );
}
