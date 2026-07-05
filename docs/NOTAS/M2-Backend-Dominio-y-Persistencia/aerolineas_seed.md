# Aerolíneas ficticias y datos de vuelos – Seed Data

## Aerolíneas

| Código | Nombre | Color |
|--------|--------|-------|
| `ARC` | Aerolíneas del Cóndor | `#2196F3` (azul) |
| `FLS` | FlySur | `#F5A623` (naranja) |
| `PAM` | Pampa Air | `#2E7D32` (verde) |
| `CRU` | Cruz Andina | `#C62828` (rojo) |
| `ANW` | Andes Wings | `#6A1B9A` (violeta) |

---

## Aeropuertos utilizados

| Código | Aeropuerto | Ciudad |
|--------|-----------|--------|
| `EZE` | Ministro Pistarini | Buenos Aires (Ezeiza) |
| `AEP` | Jorge Newbery | Buenos Aires (Aeroparque) |
| `COR` | Ingeniero Ambrosio Taravella | Córdoba |
| `MDZ` | El Plumerillo | Mendoza |
| `BRC` | Teniente Luis Candelaria | Bariloche |
| `IGR` | Cataratas del Iguazú | Iguazú |
| `SLA` | Martín Miguel de Güemes | Salta |
| `NQN` | Presidente Perón | Neuquén |
| `TUC` | Benjamín Matienzo | Tucumán |
| `USH` | Malvinas Argentinas | Ushuaia |

---

## Vuelos por aerolínea

Cada vuelo tiene los campos: `id`, `aerolinea_id`, `origen`, `destino`, `fecha`, `hora`, `precio` (en ARS), `asientos_totales`.

### ARC – Aerolíneas del Cóndor

| ID | Origen | Destino | Fecha | Hora | Precio (ARS) | Asientos |
|----|--------|---------|-------|------|-------------|---------|
| ARC-001 | EZE | COR | 2026-01-10 | 07:00 | 80.000 | 60 |
| ARC-002 | COR | EZE | 2026-01-10 | 10:30 | 80.000 | 60 |
| ARC-003 | EZE | MDZ | 2026-02-14 | 08:15 | 95.000 | 80 |
| ARC-004 | MDZ | EZE | 2026-02-14 | 13:00 | 95.000 | 80 |
| ARC-005 | AEP | BRC | 2026-03-05 | 09:00 | 120.000 | 50 |
| ARC-006 | BRC | AEP | 2026-03-05 | 14:30 | 120.000 | 50 |
| ARC-007 | EZE | IGR | 2026-04-20 | 06:45 | 110.000 | 70 |
| ARC-008 | IGR | EZE | 2026-04-20 | 12:00 | 110.000 | 70 |
| ARC-009 | AEP | SLA | 2026-05-08 | 11:00 | 105.000 | 40 |
| ARC-010 | SLA | AEP | 2026-05-08 | 16:00 | 105.000 | 40 |

### FLS – FlySur

| ID | Origen | Destino | Fecha | Hora | Precio (ARS) | Asientos |
|----|--------|---------|-------|------|-------------|---------|
| FLS-001 | AEP | USH | 2026-01-15 | 06:00 | 180.000 | 40 |
| FLS-002 | USH | AEP | 2026-01-15 | 12:00 | 180.000 | 40 |
| FLS-003 | EZE | NQN | 2026-02-22 | 08:00 | 90.000 | 55 |
| FLS-004 | NQN | EZE | 2026-02-22 | 13:30 | 90.000 | 55 |
| FLS-005 | AEP | TUC | 2026-03-18 | 07:30 | 88.000 | 65 |
| FLS-006 | TUC | AEP | 2026-03-18 | 13:00 | 88.000 | 65 |
| FLS-007 | EZE | COR | 2026-04-11 | 10:00 | 82.000 | 75 |
| FLS-008 | COR | EZE | 2026-04-11 | 15:30 | 82.000 | 75 |
| FLS-009 | AEP | MDZ | 2026-05-25 | 09:15 | 97.000 | 50 |
| FLS-010 | MDZ | AEP | 2026-05-25 | 14:45 | 97.000 | 50 |

### PAM – Pampa Air

| ID | Origen | Destino | Fecha | Hora | Precio (ARS) | Asientos |
|----|--------|---------|-------|------|-------------|---------|
| PAM-001 | COR | MDZ | 2026-01-22 | 08:30 | 70.000 | 45 |
| PAM-002 | MDZ | COR | 2026-01-22 | 12:00 | 70.000 | 45 |
| PAM-003 | EZE | BRC | 2026-02-08 | 07:00 | 115.000 | 60 |
| PAM-004 | BRC | EZE | 2026-02-08 | 13:00 | 115.000 | 60 |
| PAM-005 | AEP | IGR | 2026-03-29 | 08:00 | 108.000 | 55 |
| PAM-006 | IGR | AEP | 2026-03-29 | 14:00 | 108.000 | 55 |
| PAM-007 | EZE | SLA | 2026-04-05 | 09:30 | 103.000 | 40 |
| PAM-008 | SLA | EZE | 2026-04-05 | 15:00 | 103.000 | 40 |
| PAM-009 | AEP | NQN | 2026-05-17 | 10:00 | 88.000 | 50 |
| PAM-010 | NQN | AEP | 2026-05-17 | 15:30 | 88.000 | 50 |

### CRU – Cruz Andina

| ID | Origen | Destino | Fecha | Hora | Precio (ARS) | Asientos |
|----|--------|---------|-------|------|-------------|---------|
| CRU-001 | MDZ | BRC | 2026-01-30 | 09:00 | 85.000 | 35 |
| CRU-002 | BRC | MDZ | 2026-01-30 | 14:00 | 85.000 | 35 |
| CRU-003 | EZE | USH | 2026-02-18 | 06:30 | 175.000 | 45 |
| CRU-004 | USH | EZE | 2026-02-18 | 13:00 | 175.000 | 45 |
| CRU-005 | AEP | COR | 2026-03-12 | 07:45 | 78.000 | 70 |
| CRU-006 | COR | AEP | 2026-03-12 | 12:30 | 78.000 | 70 |
| CRU-007 | EZE | TUC | 2026-04-24 | 08:00 | 92.000 | 60 |
| CRU-008 | TUC | EZE | 2026-04-24 | 14:00 | 92.000 | 60 |
| CRU-009 | AEP | IGR | 2026-05-31 | 09:30 | 112.000 | 50 |
| CRU-010 | IGR | AEP | 2026-05-31 | 15:00 | 112.000 | 50 |

### ANW – Andes Wings

| ID | Origen | Destino | Fecha | Hora | Precio (ARS) | Asientos |
|----|--------|---------|-------|------|-------------|---------|
| ANW-001 | EZE | NQN | 2026-01-08 | 07:30 | 91.000 | 55 |
| ANW-002 | NQN | EZE | 2026-01-08 | 13:00 | 91.000 | 55 |
| ANW-003 | AEP | USH | 2026-02-26 | 06:15 | 182.000 | 40 |
| ANW-004 | USH | AEP | 2026-02-26 | 12:30 | 182.000 | 40 |
| ANW-005 | EZE | SLA | 2026-03-22 | 08:45 | 101.000 | 45 |
| ANW-006 | SLA | EZE | 2026-03-22 | 14:15 | 101.000 | 45 |
| ANW-007 | AEP | BRC | 2026-04-15 | 09:00 | 118.000 | 60 |
| ANW-008 | BRC | AEP | 2026-04-15 | 15:00 | 118.000 | 60 |
| ANW-009 | EZE | COR | 2026-05-20 | 10:30 | 81.000 | 75 |
| ANW-010 | COR | EZE | 2026-05-20 | 16:00 | 81.000 | 75 |
