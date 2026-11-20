import type { Fulfillment } from '@spree/sdk';
import { selectDelivery } from '@/app/actions';
import { rand } from '@/lib/format';

const META: Record<string, { icon: string; eta: string }> = {
  Courier: { icon: '🚚', eta: '2–4 working days' },
  Collect: { icon: '📦', eta: '3–7 working days · collect at a pickup point near you, open late & weekends' },
  Express: { icon: '⚡', eta: 'Next working day in Joburg, Pretoria, Cape Town & Durban' },
};

export function DeliveryOptions({ fulfillments }: { fulfillments: Fulfillment[] }) {
  if (fulfillments.length === 0) {
    return <p className="font-bold text-flame">We can’t deliver to this address yet. Please check your province and postal code.</p>;
  }
  return (
    <div className="space-y-6">
      {fulfillments.map((f, idx) => (
        <div key={f.id} className="space-y-3">
          {fulfillments.length > 1 && <p className="text-sm font-bold text-ink/60">Parcel {idx + 1} of {fulfillments.length}</p>}
          {f.delivery_rates.map((rate) => {
            const meta = Object.entries(META).find(([k]) => rate.name.startsWith(k))?.[1];
            const icon = meta?.icon ?? '🚚';
            const eta = meta?.eta;
            return (
              <form key={rate.id} action={selectDelivery}>
                <input type="hidden" name="fulfillment_id" value={f.id} />
                <input type="hidden" name="rate_id" value={rate.id} />
                <button
                  className={`flex w-full items-center gap-4 rounded-2xl border-2 border-ink p-4 text-left transition hover:bg-lime ${rate.selected ? 'bg-lime shadow-[4px_4px_0_#0b0b0f]' : 'bg-white'}`}
                  aria-pressed={rate.selected}
                >
                  <span className="text-3xl">{icon}</span>
                  <span className="flex-1">
                    <span className="block font-bold">{rate.name}</span>
                    {eta && <span className="block text-sm text-ink/60">{eta}</span>}
                  </span>
                  <span className="font-display text-lg font-extrabold">{Number(rate.cost) === 0 ? 'FREE' : rand(rate.cost)}</span>
                  <span className={`grid h-6 w-6 place-items-center rounded-full border-2 border-ink ${rate.selected ? 'bg-ink text-white' : 'bg-white'}`}>{rate.selected ? '✓' : ''}</span>
                </button>
              </form>
            );
          })}
        </div>
      ))}
    </div>
  );
}
