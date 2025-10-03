type Props = { title: string; description?: string };

export function PageHeader({ title, description }: Props) {
  return (
    <header className="flex items-center justify-between">
      <div>
        <h1 className="text-xl font-semibold tracking-tight">{title}</h1>
        {description ? (
          <p className="text-sm text-neutral-600 mt-1">{description}</p>
        ) : null}
      </div>
    </header>
  );
}

