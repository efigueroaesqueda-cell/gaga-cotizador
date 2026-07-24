// Siembra precios_gaga con los mismos estimados "cordiales, no inflados"
// que ya viven como respaldo local en index.html (_COSTOS_LOCAL). Marca
// es_estimado = true para que quede claro que no son precios oficiales
// todavía. Uso: DATABASE_URL="postgresql://..." node db/seed-precios.js

const { Client } = require('pg');

const COSTOS_LOCAL = {
  HILUX:    [3850,6200,3850,9800,3850,12500,3850,9800,3850],
  HIACE:    [4000,6500,4000,10000,4000,13000,4000],
  L200:     [3650,5800,3650,9200,3650,11800,3650,9200],
  NP300:    [3950,6400,3950,10200,3950,12800,3950],
  URVAN:    [4100,6800,4100,10500,4100,13200],
  JAC:      [3800,6000,3800,9500,3800,12000],
  TORNADO:  [2800,4500,2800,7200,2800,9000,2800],
  VW:       [2600,4200,2600,6800,2600],
  RAM4000:  [4200,7100,4200,11500,4200,14000,4200],
  TRUCK_HD: [4000,6600,4000,10800,4000,13500,4000],
  TRUCK_MID:[3400,5600,3400,8800,3400,11000,3400],
  SEDAN:    [2000,3200,2000,5200,2000,6800,2000],
};

const TIPO_VEHICULO_GRUPO = {
  'Toyota Hilux SRV Diesel':          'HILUX',
  'Toyota Hiace Commuter Diesel':     'HIACE',
  'Mitsubishi L200 Diesel':           'L200',
  'JAC Sunray Diesel':                'JAC',
  'Chevrolet Tornado Gasolina':       'TORNADO',
  'Ram 4000 Gasolina':                'RAM4000',
  'Ram ProMaster 2500 Gasolina':      'TRUCK_HD',
  'Toyota 4Runner TRD Sport Gasolina':'TRUCK_HD',
  'Ford F-150 Raptor Gasolina':       'TRUCK_HD',
  'Ford F-150 Tremor Gasolina':       'TRUCK_HD',
  'Toyota Tacoma TRD Sport Gasolina': 'TRUCK_MID',
  'Toyota Tacoma PreRunner Gasolina': 'TRUCK_MID',
  'Toyota Tacoma Pickup Gasolina':    'TRUCK_MID',
  'Toyota Land Cruiser FJ80 Gasolina':'TRUCK_HD',
  'Toyota Sequoia SR5 Gasolina':      'TRUCK_HD',
  'Chevrolet Tahoe LTZ Gasolina':     'TRUCK_HD',
  'Chevrolet Tahoe Premier Gasolina': 'TRUCK_HD',
  'Nissan Frontier D22 Gasolina':     'TRUCK_MID',
  'Nissan King Cab D21 Gasolina':     'TRUCK_MID',
  'Nissan Altima SL Gasolina':        'SEDAN',
  'Nissan Versa Advance Gasolina':    'SEDAN',
  'Nissan X-Trail Advance Gasolina':  'SEDAN',
  'Kia Forte LX Gasolina':            'SEDAN',
  'Kia Rio LX Gasolina':              'SEDAN',
  'Honda Accord EX-L Gasolina':       'SEDAN',
  'Hyundai i10 GLS Gasolina':         'SEDAN',
  'Nissan NP300 Diesel':              'NP300',
  'Nissan Urvan NV350 Diesel':        'URVAN',
  'VW Saveiro Gasolina':              'VW',
  'VW Robust Gasolina':               'VW',
};

const KMS = [10000,20000,30000,40000,50000,60000,70000,80000,90000,100000];

function filasPara(tipoVehiculo, costos) {
  const rows = [];
  KMS.forEach((km, i) => {
    const total     = costos[Math.min(i, costos.length - 1)];
    const mayor     = km % 20000 === 0;
    const refaccion = Math.round(total * 0.55);
    const manoObra  = total - refaccion;
    rows.push([tipoVehiculo, km, 'Refacción',
      mayor ? 'Afinación mayor — refacciones' : 'Cambio de aceite — refacciones',
      mayor ? 'Aceite sintético + filtro de aceite + filtro de aire' : 'Aceite sintético + filtro de aceite',
      1, refaccion, refaccion]);
    rows.push([tipoVehiculo, km, 'Mano de obra',
      mayor ? 'Afinación mayor — mano de obra' : 'Cambio de aceite — mano de obra',
      'Diagnóstico + instalación + prueba de ruta',
      1, manoObra, manoObra]);
  });
  return rows;
}

async function main() {
  const client = new Client({ connectionString: process.env.DATABASE_URL, ssl: false });
  await client.connect();

  let total = 0;
  for (const [tipoVehiculo, grupo] of Object.entries(TIPO_VEHICULO_GRUPO)) {
    const costos = COSTOS_LOCAL[grupo] || COSTOS_LOCAL.SEDAN;
    const filas = filasPara(tipoVehiculo, costos);
    for (const f of filas) {
      await client.query(
        `INSERT INTO precios_gaga (tipo_vehiculo, km_intervalo, tipo, descripcion, descripcion_sub, cantidad, precio_unitario, total, es_estimado)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8, true)
         ON CONFLICT (tipo_vehiculo, km_intervalo, tipo, descripcion)
         DO UPDATE SET descripcion_sub = EXCLUDED.descripcion_sub, cantidad = EXCLUDED.cantidad,
                        precio_unitario = EXCLUDED.precio_unitario, total = EXCLUDED.total, es_estimado = true`,
        f
      );
      total++;
    }
  }

  console.log(`Sembrados/actualizados ${total} renglones de precios para ${Object.keys(TIPO_VEHICULO_GRUPO).length} tipos de vehículo.`);
  await client.end();
}

main().catch(err => { console.error(err); process.exit(1); });
