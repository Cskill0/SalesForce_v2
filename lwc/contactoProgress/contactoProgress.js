import { LightningElement, api, wire, track } from 'lwc';
import getSeguimientoStats from '@salesforce/apex/SeguimientoControlador.getSeguimientoStats';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

export default class ContactoProgress extends LightningElement {
	@api recordId;

	@track seguimientoReciente = '';
	@track clima = 'Cargando...';

	total = 0;
	completed = 0;
	pendientes = 0;
	enProceso = 0;
	completados = 0;

	subscription = {};
	wiredStatsResult;

	get percent() {
		return this.total > 0 ? Math.round((this.completed / this.total) * 100) : 0;
	}

	@wire(getSeguimientoStats, { contactoId: '$recordId' })
	wiredStats(result) {
		this.wiredStatsResult = result;

		const { data, error } = result;
		if (data) {
			this.total = data.total || 0;
			this.completed = data.completado || 0;
			this.pendientes = data.pendiente || 0;
			this.enProceso = data.enProceso || 0;
			this.completados = data.completado || 0;

			this.seguimientoReciente = data.ultimoNombre || 'Sin seguimientos';
			this.clima = data.ultimoClima || 'Sin clima disponible';
		} else if (error) {
			console.error('Error al obtener stats:', error);
			this.clima = 'Error al cargar el clima inicial';
		}
	}

	connectedCallback() {
		this.handleSubscribe();
	}

	disconnectedCallback() {
		this.handleUnsubscribe();
	}

	handleSubscribe() {
		const messageCallback = (response) => {
			const payload = response.data.payload;
			refreshApex(this.wiredStatsResult);
		};

		subscribe('/event/Clima_Actualizado__e', -1, messageCallback).then(response => {
			this.subscription = response;
			console.log('Suscrito a Platform Event Clima_Actualizado__e', JSON.stringify(response));
		}).catch(error => {
			console.error('Error al suscribirse al Platform Event:', error);
		});

		onError(error => {
			console.error('Error en empApi:', error);
		});
	}

	handleUnsubscribe() {
		unsubscribe(this.subscription, response => {
			console.log('Desuscrito Plataforma Event', JSON.stringify(response));
		}).catch(error => {
			console.error('Error al desuscribirse:', error);
		});
	}
}
